
const express = require("express");
const cors = require("cors");
const { MongoClient } = require("mongodb");
require("dotenv").config();

const app = express();
const PORT = process.env.PORT || 5001;
const MONGO_URI = process.env.MONGO_URI || "mongodb://localhost:27017";

app.use(cors());
app.use(express.json());

let db, postsCollection;

// Improved MongoDB Connection Settings
MongoClient.connect(MONGO_URI, {
  tls: true,
  tlsAllowInvalidCertificates: true,
  connectTimeoutMS: 10000,
  socketTimeoutMS: 45000,
  serverSelectionTimeoutMS: 10000,
  retryWrites: true, 
  w: "majority"
})
  .then((client) => {
    db = client.db("messageboard");
    postsCollection = db.collection("posts");
    console.log("Connected to MongoDB");
  })
  .catch((err) => {
    console.error("❌ Failed to connect to MongoDB:", err);
    process.exit(1);
  });

// Get all posts
app.get("/posts", async (req, res) => {
  try {
    const posts = await postsCollection.find().toArray();
    res.status(200).json(posts);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch posts" });
  }
});

// Create a new post
app.post("/posts", async (req, res) => {
  const { user, content } = req.body;
  if (!user || !content) {
    return res.status(400).json({ error: "Missing user or content" });
  }

  try {
    await postsCollection.insertOne({
      user,
      content,
      timestamp: new Date(),
    });
    res.status(201).json({ message: "Post created!" });
  } catch (err) {
    res.status(500).json({ error: "Failed to create post" });
  }
});

// 404 Handler
app.use((req, res) => {
  res.status(404).json({ error: "Not Found" });
});

// Start the server
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
