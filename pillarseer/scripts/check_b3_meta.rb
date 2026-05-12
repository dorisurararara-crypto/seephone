require_relative '_helpers'
b3 = '438bbff5-8ded-4f1d-bad3-9ebd879ad3b3'  # Build #3
code, body = api(:get, "/v1/builds/#{b3}/betaBuildLocalizations")
data = JSON.parse(body)
puts "─── Build #3 betaBuildLocalizations ───"
data['data'].each do |loc|
  a = loc['attributes']
  puts "  locale=#{a['locale']} whatsNew len=#{(a['whatsNew'] || '').length}"
  puts "    preview: #{(a['whatsNew'] || '').slice(0, 100)}..."
end

puts "\n─── betaAppReviewDetails (App) ───"
code, body = api(:get, "/v1/betaAppReviewDetails/#{APP_ID}")
data = JSON.parse(body)
a = data['data']['attributes']
puts "  contactFirstName: #{a['contactFirstName']}"
puts "  contactLastName: #{a['contactLastName']}"
puts "  contactEmail: #{a['contactEmail']}"
puts "  contactPhone: #{a['contactPhone']}"
puts "  notes: #{(a['notes'] || '').slice(0, 100)}"

puts "\n─── betaAppLocalizations (App) ───"
code, body = api(:get, "/v1/apps/#{APP_ID}/betaAppLocalizations")
data = JSON.parse(body)
data['data'].each do |loc|
  a = loc['attributes']
  puts "  locale=#{a['locale']} desc=#{(a['description'] || '').length} feedback=#{a['feedbackEmail']}"
end
