module FileMarshaling
  def marshal_save filename, vocabulary
    File.open(filename, 'wb') do |f|
      f.write Marshal.dump(vocabulary)
    end
  end

  def marshal_load filename
    Marshal.load(File.binread(filename))
  end


  def self.marshal_save filename, vocabulary
    File.open(filename, 'wb') do |f|
      f.write Marshal.dump(vocabulary)
    end
  end


  def self.marshal_load filename
    Marshal.load(File.binread(filename))
  end
end
