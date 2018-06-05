DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
);

DROP TABLE IF EXISTS questions;

CREATE TABLE questions (
  question_id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  user_id INTEGER NOT NULL,
  
  FOREIGN KEY (user_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS question_follows;

CREATE TABLE question_follows (
  follow_id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  
  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS replies;

CREATE TABLE replies(
  reply_id INTEGER PRIMARY KEY,
  parent_question_id INTEGER NOT NULL,
  parent_reply_id INTEGER,
  user_id INTEGER NOT NULL,
  reply_body TEXT NOT NULL,
  
  FOREIGN KEY (parent_question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_reply_id) REFERENCES replies(reply_id),
  FOREIGN KEY (user_id) REFERENCES users(id)  
);

DROP TABLE IF EXISTS question_likes;

CREATE TABLE question_likes(
  likes_id INTEGER PRIMARY KEY,
  likes_user INTEGER NOT NULL,
  question_user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  
  FOREIGN KEY (question_user_id) REFERENCES users(id),
  FOREIGN KEY (likes_user) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);


INSERT INTO 
  users (fname, lname)
VALUES 
  ('Matt', 'Mintzer'),
  ('Daniel', 'Park');
  
INSERT INTO 
  questions (title, body, user_id)
VALUES 
  ('I don''t know', 'body of the question', 1),
  ('I don''t know 2', 'body is a wonderland', 2);
  
INSERT INTO 
  question_follows (question_id, user_id)
VALUES 
  (1, 1),
  (2, 1),
  (2, 2);
  
INSERT INTO 
  replies (parent_question_id, parent_reply_id, user_id, reply_body)
VALUES
(1, NULL , 1, 'that''s a body, alright' ),
(1, 1, 2, 'I concur');

INSERT INTO 
  question_likes (likes_user, question_user_id, question_id)
VALUES
  (1, 1, 1),
  (2, 2, 2);
  
  
