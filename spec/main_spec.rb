describe 'database' do
  def run_script(commands)
    raw_output = nil
    IO.popen('./db', 'r+') do |pipe|
      commands.each do |command|
        pipe.puts command
      end
      pipe.close_write

      raw_output = pipe.gets(nil)
    end
    raw_output.split("\n")
  end

  it 'insert and retrieves a row' do
    result = run_script([
      "insert 1 user one@pe.com",
      "select",
      ".exit",
    ])

    expect(result).to match_array([
      "db > Executed.",
      "db > (1, user,one@pe.com)",
      "Executed.",
      "db > .exit",
    ])
  end

  it 'prints error message when table is full' do
    script = (1..1401).map do|i|
      "insert #{i} user#{i} person#{i}@example.com"
    end
    script << ".exit"
    result = run_script(script)
    expect(result[-2]).to eq('db > Error: Table full.')
  end

  it 'allows inserting strings that are the maximum length' do
    long_username = "a"*32
    long_email = "a"*255
    script = [
      "insert 1 #{long_username} #{long_email}",
      "select", 
      ".exit",
    ]
    result = run_script(script)
    expect(result).to match_array([
      "db > Executed.",
      "db > (1, #{long_username},#{long_email})",
      "Executed.",
      "db > .exit",
    ])
  end

  it 'print error message if string are to long' do
    long_username = "a"*33
    long_email = "a"*256
    script = [
      "insert 1 #{long_username} #{long_email}",
      "select", 
      ".exit",
    ]
    result = run_script(script)
    expect(result).to match_array([
      "db > String is to long.",
      "db > Executed.",
      "db > .exit",
    ])
  end

  it 'prints an error message if id is negative' do
    script = [
      "insert -1 cstack fo@bar.com",
      "select", 
      ".exit",
    ]
    result = run_script(script)
    expect(result).to match_array([
      "db > ID must be positive.",
      "db > Executed.",
      "db > .exit",
    ])
  end
end
