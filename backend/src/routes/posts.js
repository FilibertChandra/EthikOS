const express = require('express');
const router = express.Router();
const Post = require('../models/Post');
const auth = require('../middleware/authMiddleware');

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

// Create a post
router.post('/', async (req, res, next) => {
  try {
    const { content } = req.body;

    const post = await Post.create({
      author: req.user.id,
      content
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