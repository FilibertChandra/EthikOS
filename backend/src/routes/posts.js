const express = require('express');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const router = express.Router();
const Post = require('../models/Post');
const auth = require('../middleware/authMiddleware');

// Store uploaded images on disk under backend/uploads/
const uploadsDir = path.join(__dirname, '..', '..', 'uploads');
fs.mkdirSync(uploadsDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadsDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, `post-${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) return cb(null, true);
    cb(new Error('Only image uploads are allowed'));
  }
});

// All routes below require authentication
router.use(auth);

// Get all posts
router.get('/', async (req, res, next) => {
  try {
    const posts = await Post.find()
      .populate('author', 'username')
      .populate('comments.user', 'username')
      .sort({ createdAt: -1 });

    res.status(200).json(posts);
  } catch (err) {
    next(err);
  }
});

// Create a post (optionally with an image, sent as multipart/form-data)
router.post('/', upload.single('image'), async (req, res, next) => {
  try {
    const { content } = req.body;

    // multer puts the saved file on req.file; expose it as a public path.
    const imageUrl = req.file ? `/uploads/${req.file.filename}` : undefined;

    // A post needs at least text or an image.
    if ((!content || !content.trim()) && !imageUrl) {
      return res.status(400).json({ message: 'Post must have text or an image' });
    }

    const post = await Post.create({
      author: req.user.id,
      content: content || '',
      imageUrl
    });

    // Populate author before returning
    const populatedPost = await Post.findById(post._id)
      .populate('author', 'username');

    res.status(201).json(populatedPost);

  } catch (err) {
    next(err);
  }
});

// Like or unlike a post
router.put('/:id/like', async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);

    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    const alreadyLiked = post.likes.includes(req.user.id);

    if (alreadyLiked) {
      // Unlike
      post.likes.pull(req.user.id);
    } else {
      // Like
      post.likes.push(req.user.id);
    }

    await post.save();

    res.status(200).json({
      message: alreadyLiked ? 'Post unliked' : 'Post liked',
      likes: post.likes.length
    });

  } catch (err) {
    next(err);
  }
});

// Add a comment to a post
router.post('/:id/comment', async (req, res) => {
  try {
    const { text } = req.body;

    const post = await Post.findById(req.params.id);

    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    post.comments.push({
      user: req.user.id,
      text
    });

    await post.save();

    res.status(201).json({
      message: 'Comment added successfully',
      comments: post.comments
    });

  } catch (err) {
      next(err);
  }
});

module.exports = router;