const mongoose = require('mongoose');

const commentSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  text: {
    type: String,
    required: [true, 'Comment text is required'],
    trim: true,
    maxlength: [300, 'Comment cannot exceed 300 characters']
  }
}, { timestamps: true });

const postSchema = new mongoose.Schema({
  author: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  content: {
    type: String,
    trim: true,
    default: '',
    maxlength: [500, 'Post cannot exceed 500 characters']
  },
  imageUrl: {
    type: String
  },
  likes: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    }
  ],
  comments: [commentSchema]
}, { timestamps: true });

module.exports = mongoose.model('Post', postSchema);