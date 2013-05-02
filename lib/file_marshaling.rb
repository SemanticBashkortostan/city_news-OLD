module FileMarshaling
  def save_hash filename, vocabulary
    File.open(filename, 'wb') do |f|
      f.write Marshal.dump(vocabulary)
    end
  end

  def load_hash filename
    Marshal.load(File.binread(filename))
  end
end
