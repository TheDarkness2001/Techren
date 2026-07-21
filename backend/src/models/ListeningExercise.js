const mongoose = require('mongoose');
const softDeletePlugin = require('../plugins/softDeletePlugin');

const listeningExerciseSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true },
    script: { type: String, required: true, trim: true },
    audioFile: { type: String, required: true },
    lessonId: { type: mongoose.Schema.Types.ObjectId, ref: 'Lesson', required: true },
    order: { type: Number, default: 1 },
  },
  { timestamps: true }
);

listeningExerciseSchema.index({ lessonId: 1, order: 1 });
listeningExerciseSchema.plugin(softDeletePlugin);

module.exports = mongoose.model('ListeningExercise', listeningExerciseSchema);
