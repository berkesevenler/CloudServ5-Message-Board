from flask import Flask, jsonify, request
import psycopg2

app = Flask(__name__)

# Database connection
def get_db_connection():
    conn = psycopg2.connect(
        dbname="message_board",
        user="admin",
        password="admin123",
        host="database"  # The hostname matches the Docker service name for the database
    )
    return conn

@app.route('/posts', methods=['GET', 'POST'])
def posts():
    conn = get_db_connection()
    cur = conn.cursor()

    if request.method == 'GET':
        cur.execute('SELECT * FROM posts')
        posts = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify(posts)

    if request.method == 'POST':
        new_post = request.json
        cur.execute(
            'INSERT INTO posts (user, content) VALUES (%s, %s)',
            (new_post['user'], new_post['content'])
        )
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({'message': 'Post created!'}), 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
