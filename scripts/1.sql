CREATE TABLE users (
	id serial PRIMARY KEY,
	username VARCHAR ( 50 ) UNIQUE NOT NULL,
	"password" VARCHAR ( 50 ),
	email VARCHAR ( 255 ) UNIQUE NOT NULL
);