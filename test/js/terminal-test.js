// Test various ANSI sequences and terminal control characters
module.exports = {
  outputWithANSI: () => {
    // Color and formatting
    process.stdout.write('\u001b[31mred text\u001b[0m\n');
    process.stdout.write('\u001b[1mbold text\u001b[0m\n');
    
    // Cursor movement
    process.stdout.write('\u001b[2Amove up\n');
    process.stdout.write('\u001b[2Bmove down\n');
    
    // Screen control
    process.stdout.write('\u001b[2Jclear screen\n');
    process.stdout.write('\u001b[?25linvisible cursor\n');
    
    // Return a clean string to verify protocol handling
    return "clean output";
  },

  // Test function that outputs complex ANSI sequences
  complexOutput: () => {
    // Nested and compound sequences
    process.stdout.write('\u001b[1m\u001b[31m\u001b[4mcomplex formatting\u001b[0m\n');
    
    // OSC sequences (window title, etc)
    process.stdout.write('\u001b]0;Window Title\u0007');
    
    // Alternative screen buffer
    process.stdout.write('\u001b[?1049h\u001b[Halternate screen\u001b[?1049l');
    
    return "complex test passed";
  }
}
