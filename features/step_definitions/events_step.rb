# Visit the new event page
When("I visit the new event page") do
  visit "/events/new"
end

# Fill in the event form using a table of values
When("I fill in the event form with:") do |table|
  data = table.rows_hash

  if data["Event Name"]
    fill_in "Event Name", with: data["Event Name"]
  end

  if data["Event Date"]
    case data["Event Date"]
    when "tomorrow"
      date = (Date.today + 1).strftime("%Y-%m-%d")
    when "future date"
      date = (Date.today + 7).strftime("%Y-%m-%d")
    when "yesterday"
      date = (Date.today - 1).strftime("%Y-%m-%d")
    else
      # assume already in YYYY-MM-DD format
      date = data["Event Date"]
    end

    fill_in "Event Date", with: date
  end

  fill_in "Location", with: data["Location"] if data["Location"]
  fill_in "Budget", with: data["Budget"] if data["Budget"]
  fill_in "Description", with: data["Description"] if data["Description"]
end