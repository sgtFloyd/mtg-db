require 'fileutils'

working_dir = ['data', 'images', 'mgci (312x445)']
originals = File.join(*working_dir, 'original', '*', '*.jpg')
original_pngs = File.join(*working_dir, 'png', '*', '*.png')

Dir[originals].each do |input|
  dir, file = File.split(input)
  set = File.split(dir).last
  base = file.chomp(File.extname(file))

  png_out = File.join(*working_dir, 'png', set, base+'.png')
  FileUtils.mkdir_p File.dirname(png_out)
  # `convert \"#{input}\" \"#{png_out}\"`

  pq_ext = "-pq.png"
  `pngquant \"#{png_out}\" --force --ext #{pq_ext} --speed 1`
  pq_out = File.join(*working_dir, 'png', set, base+pq_ext)

  pq_move = File.join(*working_dir, 'pngquant', set, base+'.png')
  FileUtils.mkdir_p File.dirname(pq_move)
  `mv \"#{pq_out}\" \"#{pq_move}\"`
  print '.'
end
