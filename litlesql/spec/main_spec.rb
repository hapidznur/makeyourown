describe 'database' do
  before do
    `rm -rf test.db`
  end

  def run_script(commands)
    raw_output = nil
    IO.popen('./db test.db', 'r+') do |pipe|
      commands.each do |command|
        begin
          pipe.puts command
        rescue Errno::EPIPE
           break
        end
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
      "db > (1, user, one@pe.com)",
      "Executed.",
      "db > ",
    ])
  end

  it 'prints error message when table is full' do
    script = (1..1401).map do |i|
      "insert #{i} user#{i} person#{i}@example.com"
    end
    script << ".exit"
    result = run_script(script)
    expect(result.last(2)).to match([
        "db > Executed.",
        "db > Need to implement splitting internal node"
    ])
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
      "db > (1, #{long_username}, #{long_email})",
      "Executed.",
      "db > ",
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
      "db > ",
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
      "db > ",
    ])
  end
  
  it 'keeps data after closing connection' do 
    result1 = run_script([
      "insert 1 user1 person@example.com",
      ".exit",
    ])
    expect(result1).to match_array([
      "db > Executed.",
      'db > '
    ])
    result1 = run_script([
      "select",
      ".exit",
    ])
    expect(result1).to match_array([
      "db > (1, user1, person@example.com)",
      "Executed.",
      "db > ",
    ])
  end

  it 'prints constants' do
    script = [
      ".constants",
      ".exit"
    ]
    result = run_script(script)
    expect(result).to match_array([
      "db > Constants:",
      "ROW_SIZE: 293",
      "COMMON_NODE_HEADER_SIZE: 6",
      "LEAF_NODE_HEADER_SIZE: 14",
      "LEAF_NODE_CELL_SIZE: 297",
      "LEAF_NODE_SPACE_FOR_CELLS: 4082",
      "LEAF_NODE_MAX_CELLS: 13",
      "db > ",
    ])
  end

  it 'allows printing out the structure of a one-node btree' do
    script = [3,1,2].map do |i|
      "insert #{i} user#{i} person#{i}@example.com"
    end
    script << ".btree"
    script << ".exit"
    result = run_script(script)
    expect(result).to match_array([
      "db > Executed.",
      "db > Executed.",
      "db > Executed.",
      "db > Tree:",
      "- leaf (size 3)",
      "  - 1",
      "  - 2",
      "  - 3",
      "db > ",
    ])
  end

  it 'prints an error message if there is a duplicate id' do
    script = [
      "insert 1 user1 person1@example.com",
      "insert 1 user1 person1@example.com",
      "select",
      ".exit"
    ]
    result = run_script(script)
    expect(result).to match_array([
      "db > Executed.",
      "db > Error: Duplicate key.",
      "db > (1, user1, person1@example.com)",
      "Executed.",
      "db > "
    ])

  end
  it '' do
    script = (1..14).map do |i|
      "insert #{i} user#{i} person#{i}@example.com"
    end
    script << ".btree"
    script << "insert 15 user15 person15@example.com"
    script << ".exit"
    result = run_script(script)
  expect(result[14...(result.length)]).to match_array([

      "db > Tree:",
      "- internal (size 1)",
      "  - leaf (size 7)",
      "    - 1",
      "    - 2",
      "    - 3",
      "    - 4",
      "    - 5",
      "    - 6",
      "    - 7",
      "  - key 7",
      "  - leaf (size 7)",
      "    - 8",
      "    - 9",
      "    - 10",
      "    - 11",
      "    - 12",
      "    - 13",
      "    - 14",
      "db > Executed.",
      "db > ",
    ])
  end
  it 'print all row in a multi-level tree' do
    script = []
    (1..15).each do |i|
      script << "insert #{i} user#{i} person#{i}@m.com"
    end
    script << "select"
    script << ".exit"
    result = run_script(script)
    expect(result[15...(result.length)]).to match_array([
      "db > (1, user1, person1@m.com)",
      "(2, user2, person2@m.com)",
      "(3, user3, person3@m.com)",
      "(4, user4, person4@m.com)",
      "(5, user5, person5@m.com)",
      "(6, user6, person6@m.com)",
      "(7, user7, person7@m.com)",
      "(8, user8, person8@m.com)",
      "(9, user9, person9@m.com)",
      "(10, user10, person10@m.com)",
      "(11, user11, person11@m.com)",
      "(12, user12, person12@m.com)",
      "(13, user13, person13@m.com)",
      "(14, user14, person14@m.com)",
      "(15, user15, person15@m.com)",
      "Executed.",
      "db > ",
    ])
  end
  it 'allows printing out the structure of a 4-leaf-node btree' do
    script = [
      "insert 18 18 18@m.com",
      "insert 7 7 7@m.com",
      "insert 10 10 10@m.com",
      "insert 29 29 29@m.com",
      "insert 28 28 28@m.com",
      "insert 27 27 27@m.com",
      "insert 26 26 26@m.com",
      "insert 25 25 25@m.com",
      "insert 24 24 24@m.com",
      "insert 23 23 23@m.com",
      "insert 22 22 22@m.com",
      "insert 21 21 21@m.com",
      "insert 20 20 20@m.com",
      "insert 19 19 19@m.com",
      "insert 17 17 17@m.com",
      "insert 16 16 16@m.com",
      "insert 15 15 15@m.com",
      "insert 14 14 14@m.com",
      "insert 13 13 13@m.com",
      "insert 12 12 12@m.com",
      "insert 12 12 12@m.com",
      "insert 11 11 11@m.com",
      "insert 9 9 9@m.com",
      "insert 8 8 8@m.com",
      "insert 6 6 6@m.com",
      "insert 5 5 5@m.com",
      "insert 4 4 4@m.com",
      "insert 3 3 3@m.com",
      "insert 2 2 2@m.com",
      "insert 1 1 1@m.com",
      ".btree",
      ".exit"
    ]
    result = run_script(script)
    expect(result[15...(result.length)]).to match_array([
      "db > Tree:",
      "- internal (size 3)",
      "  - leaf (size 7)",
      "    - 1",
      "    - 2",
      "    - 3",
      "    - 4",
      "    - 5",
      "    - 6",
      "    - 7",
      "  - key 7",
      "  - leaf (size 8)",
      "    - 8",
      "    - 9",
      "    - 10",
      "    - 11",
      "    - 12",
      "    - 13",
      "    - 14",
      "    - 15",
      "  - key 15",
      "  - leaf (size 7)",
      "    - 16",
      "    - 17",
      "    - 18",
      "    - 19",
      "    - 20",
      "    - 21",
      "    - 22",
      "  - key 22",
      "  - leaf (size 8)",
      "    - 23",
      "    - 24",
      "    - 25",
      "    - 26",
      "    - 27",
      "    - 28",
      "    - 29",
      "    - 30",
      "db > ",
    ])
  end
end
