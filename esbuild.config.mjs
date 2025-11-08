import * as esbuild from 'esbuild';
import path from 'path';

const watch = process.argv.includes('--watch');
const minify = process.env.NODE_ENV === 'production';

const config = {
  entryPoints: ['app/javascript/application.js'],
  bundle: true,
  sourcemap: true,
  format: 'iife',
  outdir: path.join(process.cwd(), 'app/assets/builds'),
  publicPath: '/assets',
  minify,
  loader: {
    '.js': 'jsx',
    '.png': 'file',
    '.jpg': 'file',
    '.jpeg': 'file',
    '.svg': 'file',
    '.woff': 'file',
    '.woff2': 'file',
    '.ttf': 'file',
    '.eot': 'file'
  }
};

if (watch) {
  const context = await esbuild.context(config);

  await context.watch();
  console.log('👀 Watching for changes...');
} else {
  await esbuild.build(config);
}
