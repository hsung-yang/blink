// Claude Code — One Dark palette, GitHub Dark bg/fg
// Optimized for Claude Code CLI: high contrast, no cursor blink, truecolor
var black        = '#282c34';
var red          = '#e06c75';
var green        = '#98c379';
var yellow       = '#e5c07b';
var blue         = '#61afef';
var magenta      = '#c678dd';
var cyan         = '#56b6c2';
var white        = '#abb2bf';
var brightBlack  = '#5c6370';
var brightRed    = '#e06c75';
var brightGreen  = '#98c379';
var brightYellow = '#e5c07b';
var brightBlue   = '#61afef';
var brightMagenta= '#c678dd';
var brightCyan   = '#56b6c2';
var brightWhite  = '#ffffff';

term_set('color-palette-overrides',
  [black,       red,       green,       yellow,
   blue,        magenta,   cyan,        white,
   brightBlack, brightRed, brightGreen, brightYellow,
   brightBlue,  brightMagenta, brightCyan, brightWhite]);

term_set('foreground-color', '#c9d1d9');
term_set('background-color', '#0d1117');
term_set('cursor-color', '#c9d1d9');
term_set('cursor-blink', false);
term_set('enable-bold', true);
term_set('bold-color-as-bright', true);
