from flask import Flask, jsonify, request
from flask_cors import CORS
from pymongo import MongoClient
import datetime
import os

app = Flask(__name__)

# Enable CORS for the frontend's origin
CORS(app, resources={r"/*": {"origins": "*"}})

# MongoDB connection
mongo_uri = os.getenv("MONGO_URI", "mongodb://localhost:27017/messageboard")
client = MongoClient(mongo_uri)
db = client.get_database()
posts_collection = db.posts

@app.route('/posts', methods=['GET', 'POST'])
def posts():
    if request.method == 'GET':
        posts = []
        for post in posts_collection.find():
            posts.append({
                "id": str(post["_id"]),
                "user": post["user"],
                "content": post["content"],
                "timestamp": post["timestamp"]
            })
        return jsonify(posts)

    if request.method == 'POST':
        data = request.get_json()
        user = data.get('user')
        content = data.get('content')

        if not user or not content:
            return jsonify({'error': 'Missing user or content'}), 400

        post = {
            "user": user,
            "content": content,
            "timestamp": datetime.datetime.utcnow()
        }
        result = posts_collection.insert_one(post)
        return jsonify({'message': 'Post created!', 'id': str(result.inserted_id)}), 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
