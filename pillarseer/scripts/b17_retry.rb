require_relative '_helpers'
b17 = '6df80630-26e5-48c4-833e-8fcf55f6124e'

# 409 details
code, body = api(:get, "/v1/builds/#{b17}/betaBuildLocalizations")
locs = JSON.parse(body)['data']
locs.each do |l|
  loc_id = l['id']
  locale = l['attributes']['locale']
  text = locale == 'ko' ? 'v1.0.0 Build #17 정식 릴리즈 노트' : 'v1.0.0 Build #17 official release notes'
  code, body = api(:patch, "/v1/betaBuildLocalizations/#{loc_id}",
                   {data: {type: 'betaBuildLocalizations', id: loc_id,
                           attributes: {whatsNew: text}}})
  puts "PATCH #{locale}: HTTP #{code}"
  puts "  body: #{body[0..300]}" if code.to_i >= 400
end
