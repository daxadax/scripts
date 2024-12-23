SIZE = 10
RULES = {
  0 => [0, 1],
  1 => [0, 1, 2],
  2 => [1, 2, 3],
  3 => [2, 3]
}

LAND_TYPE_MAP = {
  0 => ['^', :grey], # mountain
  1 => ['$', :dark_green], # forest
  2 => [')', :light_green], # plains
  3 => ['.', :tan]  # desert
}

def color_text(text, color)
  color_code = case(color)
               when :dark_green then 46
               when :grey then 47
               when :light_green then 42
               when :tan then 43
               end

  "\001\e[#{color_code}m\002#{text}\001\e[0m\002"
end

def build_grid
  grid = Array.new(SIZE) { Array.new(SIZE) }

  starting_point = [rand(SIZE), rand(SIZE)]
  x = starting_point.first
  y = starting_point.last

  value = RULES.keys.sample
  grid = collapse_neighbors(grid, x, y, value)

  grid
end

def collapse_neighbors(grid, x, y, value)
  # don't run if the coordinates are out of bounds
  return if x < 0 || x >= SIZE
  return if y < 0 || y >= SIZE

  # don't run if this cell already has a value
  return unless grid[x][y].nil?

  # assign value to cell
  grid[x][y] = value

  # break if the grid is complete
  return grid unless grid.flatten.any?(nil)

  # north
  collapse_neighbors(grid, x, y - 1, select_neighboring_value(grid, x, y, value))

  # east
  collapse_neighbors(grid, x + 1, y, select_neighboring_value(grid, x + 1, y, value))

  # south
  collapse_neighbors(grid, x, y + 1, select_neighboring_value(grid, x, y + 1, value))

  # west
  collapse_neighbors(grid, x - 1, y, select_neighboring_value(grid, x - 1, y, value))

  grid
end

def select_neighboring_value(grid, x, y, value)
  print_grid(grid)
  north = grid.dig(x, y - 1)
  east  = grid.dig(x + 1, y)
  south = grid.dig(x, y + 1)
  west  = grid.dig(x - 1, y)

  possible_values = []
  [north, east, south, west].each do |direction|
    next if direction.nil?

    possible_values << RULES[direction]
  end

  possible_values.
    push(RULES[value]).
    compact.
    reduce { |a,b| a & b }.
    sample
end

def print_grid(data)
  sleep 0.1
  system "clear"

  data.each do |row|
    # puts row.inspect
    puts row.map { |x| next if x.nil?; color_text(*LAND_TYPE_MAP[x]) }.join(' | ')
  end
end

grid = build_grid
print_grid(grid)
nil
