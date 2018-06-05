require 'sqlite3'
require 'singleton'

class QuestionDatabase < SQLite3::Database
  include Singleton
  def initialize
    super('questions.db')
      self.type_translation = true
      self.results_as_hash = true
  end
end

class User
  attr_accessor :fname, :lname
  
  def self.all 
    data = QuestionDatabase.instance.execute("SELECT * FROM users")
    data.map { |datum| User.new(datum) }
  end
  
  def self.find_by_name(fname, lname)
    data = QuestionDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT 
      *
      FROM 
      users
      WHERE
      fname = ? AND lname = ?
    SQL
    
    data.map { |datum| Reply.new(datum) }
  end
  
  def self.find_by_id(id)
    user = QuestionDatabase.instance.execute(<<-SQL, id)
    SELECT 
    *
    FROM
    users 
    WHERE
    id = ?
    SQL
    user.map { |datum| User.new(datum) }
  end 

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end
  
  def authored_questions
    Question.find_by_author_id(@id)
  end
  
  def authored_replies
    Reply.find_by_user_id(@id)
  end
  
  def followed_questions 
    QuestionFollow.followed_questions_for_user_id(@user_id)
  end
  
end 

class Question 
  attr_accessor :title, :body, :user_id
  
  def self.all 
    data = QuestionDatabase.instance.execute("SELECT * FROM questions")
    data.map { |datum| Question.new(datum) }
  end
  
  def self.find_by_id(id)
    question = QuestionDatabase.instance.execute(<<-SQL, id) 
    SELECT 
    *
    FROM
    questions 
    WHERE
    id = ? 
    SQL
    question.map { |datum| Question.new(datum) }
  end 
  
  def self.find_by_author_id(author_id)
    question = QuestionDatabase.instance.execute(<<-SQL, author_id)
    SELECT
      *
    FROM
      questions
    WHERE 
      user_id = ? 
    SQL
    question.map { |datum| Question.new(datum) }
  end
  
  def followers
    QuestionFollow.followers_for_question_id(@question_id)
  end
  
  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @user_id = options['user_id']
  end
  
  def author 
    User.find_by_id(@user_id)
  end
  
  def replies
    Reply.find_by_question_id(@id)
  end
end

class QuestionFollow
  attr_accessor :question_id, :user_id
  
  def self.all 
    data = QuestionDatabase.instance.execute("SELECT * FROM question_follows")
    return nil if data.empty?
    data.map { |datum| QuestionFollow.new(datum) }
  end
  
  def self.find_by_id(id)
    data = QuestionDatabase.instance.execute(<<-SQL, id)
    SELECT
    *
    FROM
    question_follows
    WHERE
    id = ?     
    SQL
    return nil if data.empty?
    data.map { |datum| QuestionFollow.new(datum) }
  end 
  
  def self.followers_for_question_id(question_id)
    #this is where we stopped returning an array of followers for a question
      data = QuestionDatabase.instance.execute(<<-SQL, question_id)
        SELECT
          *
        FROM
          question_follows
        JOIN 
          users ON users.id = question_follows.question_id
        WHERE 
          question_id = ?
      SQL
      return nil if data.empty?
      data.map { |datum| User.new(datum) }
  end
  
  def self.followed_questions_for_user_id(user_id)
    data = QuestionDatabase.instance.execute(<<-SQL, user_id)
      SELECT 
        *
      FROM 
        question_follows
      JOIN 
        questions ON questions.question_id = question_follows.question_id
      WHERE 
        question_follows.user_id = ?
    SQL
    return nil if data.empty?
    data.map { |datum| Question.new(datum) }
  end

  def initialize(options) 
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end
end

class Reply
  attr_accessor :parent_question_id, :parent_reply_id, :user_id, :reply_body
  
  def self.all 
    data = QuestionDatabase.instance.execute("SELECT * FROM replies")
    data.map { |datum| Reply.new(datum) }
  end
  
  def self.find_by_user_id(user_id)
    data = QuestionDatabase.instance.execute(<<-SQL, user_id) 
      SELECT 
      *
      FROM 
      replies
      WHERE
      user_id = ? 
      SQL
    
    data.map { |datum| Reply.new(datum) }
  end
  
  def self.find_by_id(id)
    data = QuestionDatabase.instance.execute(<<-SQL, id)
    SELECT
    *
    FROM
    replies 
    WHERE
    id = ?     
    SQL
    data.map { |datum| QuestionFollow.new(datum) }
  end 
  
  def self.find_by_question_id(question_id)
    data = QuestionDatabase.instance.execute(<<-SQL, question_id)
    SELECT
    *
    FROM
    replies 
    WHERE
    parent_question_id = ?     
    SQL
    data.map { |datum| QuestionFollow.new(datum) }
  end
  
  def initialize(options)
    @id = options['id']
    @parent_question_id = options['parent_question_id']
    @parent_reply_id = options['parent_reply_id']
    @user_id = options['user_id']
    @reply_body = options['reply_body']
  end
  
  def author 
    User.find_by_id(@user_id)
  end 
  
  def question 
    Question.find_by_id(@parent_question_id)
  end 
  
  def parent_reply 
    Reply.find_by_id(@parent_reply_id)
  end 
  
  def child_replies
    data = QuestionDatabase.instance.execute(<<-SQL, @id)
      SELECT
      *
      FROM
      replies 
      WHERE
      parent_reply_id = ? 
    SQL
    data.map { |datum| Reply.new(datum) }
  end 
end
  
class QuestionLike 
  attr_accessor :likes_user, :question_user_id, :question_id 
  
  def self.all 
    data = QuestionDatabase.instance.execute("SELECT * FROM question_likes")
    data.map { |datum| QuestionLike.new(datum) }
  end
  
  def self.find_by_id
    data = QuestionDatabase.instance.execute(<<-SQL, id)
    SELECT
    *
    FROM
    question_likes 
    WHERE
    id = ?     
    SQL
    data.map { |datum| QuestionFollow.new(datum) }
  end 
  
  def initialize(options)
    @id = options['id']
    @likes_user = options['likes_user']
    @question_user_id = options['question_user_id']
    @question_id = options['question_id']
  end
end