require './modules/search'
require './controllers/main'
require './controllers/directory'
require './models/station'
require './models/connection'
require './models/route'

## Driver Code
test_file = ARGV[0] || 'test_input.txt'
test_input = File.read(test_file).split(', ')
search_by = Directory.new(test_input)

## Sanity Check
## Expected Output:
p "#1: #{search_by.distance_along_route('A','B','C') == 9}"
p "#2: #{search_by.distance_along_route('A','D') == 5}"
p "#3: #{search_by.distance_along_route('A','D','C') == 13}"
p "#4: #{search_by.distance_along_route('A','E','B','C','D') == 22}"
p "#5: #{search_by.distance_along_route('A','E','D') == 'NO SUCH ROUTE'}"
p "#6: #{search_by.total_routes_between('C','C',3) == 2}"
p "#7: #{search_by.total_routes_between('A','C',4,4) == 3}"
p "#8: #{search_by.shortest_distance_between('A','C') == 9}"
p "#9: #{search_by.shortest_distance_between('B','B') == 9}"
p "#10: #{search_by.total_routes_by_limit_distance('C','C',30) == 7}"