const svgrPlugin = require('esbuild-plugin-svgr');

let watch = false;

if (process.env.WATCH == "true") {
  watch = {
    onRebuild(error, result) {
      if (error) console.error('watch build failed:', error)
      else console.log('watch build succeeded:', result)
    },
  };
}

require('esbuild').build({
  entryPoints: ['js/app.js'],
  bundle: true,
  outdir: '../priv/static/js',
  plugins: [
    svgrPlugin(),
  ],
  watch
}).catch(() => process.exit(1))
