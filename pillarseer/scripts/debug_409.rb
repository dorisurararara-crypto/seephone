require_relative '_helpers'

b16 = '3b51b143-3c41-47b8-8228-15fb717c8b1b'
code, body = api(:get, "/v1/builds/#{b16}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
locs.each do |l|
  loc_id = l['id']
  whats_new = 'TEST UPDATE'
  code, body = api(:patch, "/v1/betaBuildLocalizations/#{loc_id}",
                   {data: {type: 'betaBuildLocalizations', id: loc_id,
                           attributes: {whatsNew: whats_new}}})
  puts "PATCH #{l['attributes']['locale']} #{loc_id}: HTTP #{code}"
  puts body if code.to_i >= 400
end
