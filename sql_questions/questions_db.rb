require 'sqlite3'
require 'singleton'

class QuestionDatabase < SQLite3::Database
  include singleton
  def initialize
    super('questions.db')
      self.type_translation = true
      self.results_as_hash = true
  end
end

class User
  attr_accessor :fname, :lname
  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end
end

class Question 
  attr_accessor :title, :body, :user_id
  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @user_id = options['user_id']
  end
end

class QuestionFollows
  attr_accessor :question_id, :user_id
  def initialize(options) 
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end
end

class Replies 
  attr_accessor :parent_question_id, :parent_reply_id, :user_id, :reply_body
  def initialize(options)
    @id = options['id']
    @parent_question_id = options['parent_question_id']
    @parent_reply_id = options['parent_reply_id']
    @user_id = options['user_id']
    @reply_body = options['reply_body']
  end
end

class QuestionLikes 
  attr_accessor :likes_user, :question_user_id, :question_id 
  def initialize(options)
    @id = options['id']
    @likes_user = options['likes_user']
    @question_user_id = options['question_user_id']
    @question_id = options['question_id']
  end
end