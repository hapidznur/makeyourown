db: db.c
		gcc db.c -o db
run: db
		./db mydb.db
clean: 
		rm -rf db *db
test: db
		bundle exec rspec
