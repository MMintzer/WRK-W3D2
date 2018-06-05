require 'byebug'
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
  attr_reader :id
  
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
    user_array = QuestionDatabase.instance.execute(<<-SQL, id)
    SELECT 
    *
    FROM
    users 
    WHERE
    id = ?
    SQL
    User.new(user_array.first)
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
    QuestionFollow.followed_questions_for_user_id(@id)
  end
  
  def liked_questions 
    QuestionLike.liked_questions_for_user_id(@id)
  end
  
  def average_karma 
    data = QuestionDatabase.instance.execute(<<-SQL, id)
    SELECT
    count(question_likes.likes_id) AS num_likes
    FROM
    users 
    JOIN 
    questions ON questions.user_id = users.id
    JOIN 
    question_likes ON question_likes.question_id = questions.question_id 
    WHERE 
    users.id = ?
    -- GROUP BY 
    -- users.id

    SQL
    
    data.first['num_likes'] / number_of_questions
  end 
  
  def save 
    raise "#{self} already exists " if @id 
    QuestionDatabase.instance.execute(<<-SQL, @id, @fname, @lname)
      INSERT INTO 
        users (id, fname, lname)
      VALUES 
        (?, ?, ?)
    SQL
  end
  
  def update 
    raise "#{self} already exists " unless @id 
    QuestionDatabase.instance.execute(<<-SQL, @id, @fname, @lname)
      UPDATE 
        users
      SET 
       id = ?, fname = ?, lname = ?
       WHERE 
       id = ?
    SQL
  end
  
  private 
  
  def number_of_questions
    authored_questions.length
  end 
end 

class Question 
  attr_accessor :title, :body, :user_id
  
  def self.all 
    data = QuestionDatabase.instance.execute("SELECT * FROM questions")
    data.map { |datum| Question.new(datum) }
  end
  
  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
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
  
  def likers
    QuestionLike.likers_for_question_id(@id)
  end
  
  def num_likes 
    QuestionLike.num_likes_for_question_id(@id)
  end
  
  def most_liked(n)
    QuestionLike.most_liked_questions(n)
  end
  
  def save 
    raise "#{self} already exists " if @id 
    QuestionDatabase.instance.execute(<<-SQL, @id, @title, @body, @user_id)
      INSERT INTO 
        questions (id, title, body, user_id)
      VALUES 
        (?, ?, ?, ?)
    SQL
  end
  
  def update 
    raise "#{self} already exists " unless @id 
    QuestionDatabase.instance.execute(<<-SQL, @id, @title, @body, @user_id)
      UPDATE 
        questions
      SET 
       question_id = ?, title = ?, body = ?, user_id = ?
       WHERE 
       question_id = ?
    SQL
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
  
  def self.most_followed_questions(n)
    data = QuestionDatabase.instance.execute(<<-SQL, n)
        SELECT 
          *
        FROM 
          question_follows
        JOIN 
          questions ON question_follows.question_id = questions.question_id
        GROUP BY 
          question_follows.question_id
        ORDER BY 
          count(question_follows.user_id) DESC 
        LIMIT ?
          
    SQL
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
  
  def save 
    raise "#{self} already exists " if @id 
    QuestionDatabase.instance.execute(<<-SQL, @id, @parent_question_id, @parent_reply_id, @user_id, @reply_body)
      INSERT INTO 
        replies (reply_id, parent_question_id, parent_reply_id, user_id, reply_body )
      VALUES 
        (?, ?, ?, ?, ?)
    SQL
  end
  
  def update 
    raise "#{self} already exists " unless @id 
    QuestionDatabase.instance.execute(<<-SQL, @parent_question_id, @parent_reply_id, @user_id, @reply_body)
      UPDATE 
        replies
      SET 
       reply_id = ?, parent_question_id = ?, parent_reply_id = ?, user_id = ?, reply_body = ?
       WHERE 
       id = ?
    SQL
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
  
  def self.likers_for_questions_id(question_id)
    data = QuestionDatabase.instance.execute(<<-SQL, question_id)
      SELECT
      *
      FROM
      users
      JOIN 
      question_likes ON users.id = question_likes.likes_user
      WHERE 
      question_likes.question_id = ?
          
    SQL
    return nil if data.empty?
    data.map { |datum| User.new(datum) }
  end  
  
  def self.num_likes_for_question_id(question_id)
    data = QuestionDatabase.instance.execute(<<-SQL, question_id)
    SELECT
    count(question_likes.likes_id)
    FROM
    questions 
    JOIN 
    question_likes ON question_likes.question_id = questions.question_id 
    WHERE 
    questions.question_id = ?
    GROUP BY  -- Not compltely necessary (GROUP BY)
    questions.question_id
    SQL
    data 
  end
  
  def self.most_liked_questions(n)
    data = QuestionDatabase.instance.execute(<<-SQL, n)
    SELECT
    * 
    FROM
    questions 
    JOIN 
    question_likes ON question_likes.question_id = questions.question_id 
    GROUP BY  
    questions.question_id
    ORDER BY 
     count(question_likes.likes_id) DESC
     LIMIT ?
    SQL
    return nil if data.empty?
    data.map { |datum| Question.new(datum) }
    
  end
  
  def self.liked_question_for_user_id(user_id)
    data = QuestionDatabase.instance.execute(<<-SQL, user_id)
      SELECT 
        *
      FROM 
        questions
      JOIN 
        question_likes ON question_likes.question_id = questions.question_id
      WHERE 
        question_likes.likes_user = ?
    SQL
  end
  
  def initialize(options)
    @id = options['id']
    @likes_user = options['likes_user']
    @question_user_id = options['question_user_id']
    @question_id = options['question_id']
  end
end