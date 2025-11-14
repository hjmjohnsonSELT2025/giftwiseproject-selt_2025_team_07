# CREATE EVENT - TEST SCENARIOS

## POSITIVE TEST SCENARIOS (Happy Path)

### TC-CE-001: Create event with all fields filled
**Priority:** High
**Preconditions:**
- User is logged in
- User is on the Create Event page (/events/new)

**Test Steps:**
1. Fill in "Event Name" with "Mom's Birthday Party"
2. Fill in "Event Date" with "2025-12-25"
3. Fill in "Location" with "Home"
4. Fill in "Budget" with "500"
5. Fill in "Description" with "Surprise birthday celebration for mom"
6. Click "Create Event" button

**Expected Results:**
- User is redirected to dashboard (/dashboard)
- Success message displays: "Event 'Mom's Birthday Party' created successfully!"
- Event is saved in database with all fields
- Event count on dashboard increases by 1
- Event appears in "Recent Events" section

**Test Data:**
- event_name: "Mom's Birthday Party"
- event_date: "2025-12-25"
- location: "Home"
- budget: 500.00
- description: "Surprise birthday celebration for mom"

---

### TC-CE-002: Create event with only required fields
**Priority:** High
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Fill in "Event Name" with "Team Meeting"
2. Fill in "Event Date" with tomorrow's date
3. Leave all other fields empty
4. Click "Create Event" button

**Expected Results:**
- User is redirected to dashboard
- Success message displays: "Event 'Team Meeting' created successfully!"
- Event is saved with empty optional fields (location, budget, description)
- Event count increases by 1

**Test Data:**
- event_name: "Team Meeting"
- event_date: Date.tomorrow
- location: null
- budget: null
- description: null

---

### TC-CE-003: Create event with today's date
**Priority:** Medium
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Fill in "Event Name" with "Today's Event"
2. Fill in "Event Date" with today's date
3. Click "Create Event" button

**Expected Results:**
- Event is created successfully
- Success message is displayed
- Event appears in "Upcoming Events" section

**Test Data:**
- event_name: "Today's Event"
- event_date: Date.today

---

### TC-CE-004: Create event with budget as 0
**Priority:** Medium
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Fill in "Event Name" with "Free Event"
2. Fill in "Event Date" with tomorrow's date
3. Fill in "Budget" with "0"
4. Click "Create Event" button

**Expected Results:**
- Event is created successfully
- Budget is saved as 0.00
- Event displays with $0.00 budget

**Test Data:**
- event_name: "Free Event"
- event_date: Date.tomorrow
- budget: 0

---

### TC-CE-005: Create event with decimal budget
**Priority:** Medium
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Fill in "Event Name" with "Dinner Party"
2. Fill in "Event Date" with next week's date
3. Fill in "Budget" with "499.99"
4. Click "Create Event" button

**Expected Results:**
- Event is created successfully
- Budget is saved as 499.99
- Budget displays as $499.99

**Test Data:**
- event_name: "Dinner Party"
- event_date: Date.today + 7.days
- budget: 499.99

---

### TC-CE-006: Create event with location from dropdown
**Priority:** Low
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Fill in "Event Name" with "Beach Party"
2. Fill in "Event Date" with future date
3. Click on "Location" field
4. Select "Beach" from dropdown suggestions
5. Click "Create Event" button

**Expected Results:**
- Event is created successfully
- Location is saved as "Beach"
- Location autocomplete suggestions appear when clicking field

**Test Data:**
- event_name: "Beach Party"
- event_date: Date.today + 10.days
- location: "Beach"

---

### TC-CE-007: Create event with recipients selected
**Priority:** High
**Preconditions:**
- User is logged in
- User has created 2 recipients: "Mom" and "Dad"
- User is on the Create Event page

**Test Steps:**
1. Fill in "Event Name" with "Family Dinner"
2. Fill in "Event Date" with future date
3. Check boxes for recipients "Mom" and "Dad"
4. Click "Create Event" button

**Expected Results:**
- Event is created successfully
- 2 event_recipient records are created
- Event is associated with both recipients
- event_recipients table has user_id, event_id, and recipient_id

**Test Data:**
- event_name: "Family Dinner"
- event_date: Date.today + 5.days
- recipient_ids: [1, 2]

---

### TC-CE-008: Create event with long description
**Priority:** Low
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Fill in "Event Name" with "Annual Meeting"
2. Fill in "Event Date" with future date
3. Fill in "Description" with 500 characters of text
4. Click "Create Event" button

**Expected Results:**
- Event is created successfully
- Full description is saved
- Description displays correctly on event details page

**Test Data:**
- event_name: "Annual Meeting"
- event_date: Date.today + 30.days
- description: "Lorem ipsum..." (500 characters)

---

## NEGATIVE TEST SCENARIOS (Validation Failures)

### TC-CE-009: Attempt to create event without event name
**Priority:** High
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Leave "Event Name" field empty
2. Fill in "Event Date" with tomorrow's date
3. Fill in other optional fields
4. Click "Create Event" button

**Expected Results:**
- Event is NOT created
- User remains on Create Event page
- Error message displays: "Event name can't be blank"
- Form retains all entered data
- Event count does not increase

**Test Data:**
- event_name: "" (empty)
- event_date: Date.tomorrow

**Status Code:** 422 (Unprocessable Entity)

---

### TC-CE-010: Attempt to create event without event date
**Priority:** High
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Fill in "Event Name" with "No Date Event"
2. Leave "Event Date" field empty
3. Click "Create Event" button

**Expected Results:**
- Event is NOT created
- User remains on Create Event page
- Error message displays: "Event date can't be blank"
- Event count does not increase

**Test Data:**
- event_name: "No Date Event"
- event_date: null

**Status Code:** 422 (Unprocessable Entity)

---

### TC-CE-011: Attempt to create event with past date (yesterday)
**Priority:** High
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Fill in "Event Name" with "Past Event"
2. Fill in "Event Date" with yesterday's date
3. Click "Create Event" button

**Expected Results:**
- Event is NOT created
- User remains on Create Event page
- Error message displays: "Event date cannot be in the past"
- Event count does not increase

**Test Data:**
- event_name: "Past Event"
- event_date: Date.yesterday

**Status Code:** 422 (Unprocessable Entity)

---

### TC-CE-012: Attempt to create event with past date (last week)
**Priority:** Medium
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Fill in "Event Name" with "Old Event"
2. Fill in "Event Date" with "2024-01-01"
3. Click "Create Event" button

**Expected Results:**
- Event is NOT created
- Error message displays: "Event date cannot be in the past"
- Event count does not increase

**Test Data:**
- event_name: "Old Event"
- event_date: "2024-01-01"

**Status Code:** 422 (Unprocessable Entity)

---

### TC-CE-013: Attempt to create event with negative budget
**Priority:** High
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Fill in "Event Name" with "Budget Event"
2. Fill in "Event Date" with tomorrow's date
3. Fill in "Budget" with "-100"
4. Click "Create Event" button

**Expected Results:**
- Event is NOT created
- User remains on Create Event page
- Error message displays: "Budget must be greater than or equal to 0"
- Event count does not increase

**Test Data:**
- event_name: "Budget Event"
- event_date: Date.tomorrow
- budget: -100

**Status Code:** 422 (Unprocessable Entity)

---

### TC-CE-014: Attempt to create event with negative decimal budget
**Priority:** Medium
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Fill in "Event Name" with "Negative Budget"
2. Fill in "Event Date" with tomorrow's date
3. Fill in "Budget" with "-50.75"
4. Click "Create Event" button

**Expected Results:**
- Event is NOT created
- Error message displays: "Budget must be greater than or equal to 0"

**Test Data:**
- event_name: "Negative Budget"
- event_date: Date.tomorrow
- budget: -50.75

**Status Code:** 422 (Unprocessable Entity)

---

### TC-CE-015: Attempt to create event with invalid budget (text)
**Priority:** Low
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Fill in "Event Name" with "Invalid Budget"
2. Fill in "Event Date" with tomorrow's date
3. Fill in "Budget" with "abc"
4. Click "Create Event" button

**Expected Results:**
- Event is NOT created
- Error message displays: "Budget is not a number"
- Event count does not increase

**Test Data:**
- event_name: "Invalid Budget"
- event_date: Date.tomorrow
- budget: "abc"

**Status Code:** 422 (Unprocessable Entity)

---

### TC-CE-016: Attempt to create event without both required fields
**Priority:** High
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Leave "Event Name" field empty
2. Leave "Event Date" field empty
3. Click "Create Event" button

**Expected Results:**
- Event is NOT created
- User remains on Create Event page
- Multiple error messages display:
- "Event name can't be blank"
- "Event date can't be blank"
- Error count shows "2 errors prevented this event from being saved"
- Event count does not increase

**Test Data:**
- event_name: ""
- event_date: null

**Status Code:** 422 (Unprocessable Entity)

---

## EDGE CASES & BOUNDARY TESTS

### TC-CE-017: Create event with very long event name (1000 characters)
**Priority:** Low
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Fill in "Event Name" with 1000 character string
2. Fill in "Event Date" with tomorrow's date
3. Click "Create Event" button

**Expected Results:**
- Event is created successfully OR
- Error message if there's a length limit
- Verify database field can handle the length

**Test Data:**
- event_name: "A" * 1000
- event_date: Date.tomorrow

---

### TC-CE-018: Create event with special characters in name
**Priority:** Medium
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Fill in "Event Name" with "Mom's B'day @ Home! 🎉"
2. Fill in "Event Date" with tomorrow's date
3. Click "Create Event" button

**Expected Results:**
- Event is created successfully
- Special characters and emojis are saved correctly
- Event name displays correctly on dashboard

**Test Data:**
- event_name: "Mom's B'day @ Home! 🎉"
- event_date: Date.tomorrow

---

### TC-CE-019: Create event with very large budget
**Priority:** Low
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Fill in "Event Name" with "Expensive Event"
2. Fill in "Event Date" with tomorrow's date
3. Fill in "Budget" with "99999999.99"
4. Click "Create Event" button

**Expected Results:**
- Event is created successfully OR
- Error if budget exceeds database precision limits
- Budget displays correctly with proper formatting

**Test Data:**
- event_name: "Expensive Event"
- event_date: Date.tomorrow
- budget: 99999999.99

---

### TC-CE-020: Create multiple events with same name
**Priority:** Low
**Preconditions:**
- User is logged in
- User already has an event named "Birthday"
- User is on the Create Event page

**Test Steps:**
1. Fill in "Event Name" with "Birthday" (duplicate name)
2. Fill in "Event Date" with different date
3. Click "Create Event" button

**Expected Results:**
- Event is created successfully (duplicate names should be allowed)
- Both events exist separately in database
- Both events display in events list

**Test Data:**
- event_name: "Birthday" (duplicate)
- event_date: Date.today + 30.days

---

### TC-CE-021: Create event with far future date (10 years)
**Priority:** Low
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Fill in "Event Name" with "Future Event"
2. Fill in "Event Date" with "2035-12-31"
3. Click "Create Event" button

**Expected Results:**
- Event is created successfully
- Event appears in "Upcoming Events"
- Date displays correctly

**Test Data:**
- event_name: "Future Event"
- event_date: "2035-12-31"

---

## SECURITY & PERMISSION TESTS

### TC-CE-022: Attempt to create event without authentication
**Priority:** High
**Preconditions:**
- User is NOT logged in

**Test Steps:**
1. Navigate directly to /events/new
2. Try to access the create event form

**Expected Results:**
- User is redirected to login page
- Alert message displays: "Please log in to continue"
- Cannot access create event form

**Test Data:**
- N/A (unauthenticated request)

---

### TC-CE-023: Verify event is associated with correct user
**Priority:** High
**Preconditions:**
- User "John" is logged in
- Another user "Jane" exists in system

**Test Steps:**
1. As John, create an event "John's Event"
2. Verify in database that event.user_id = John's ID
3. Verify Jane cannot see John's event

**Expected Results:**
- Event is created with user_id = John's ID
- Event appears only in John's events list
- Jane cannot access John's event

**Test Data:**
- event_name: "John's Event"
- event_date: Date.tomorrow
- user_id: John's user ID

---

## UI/UX TEST SCENARIOS

### TC-CE-024: Verify $ symbol displays in budget field
**Priority:** Low
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Observe the Budget input field

**Expected Results:**
- "$" symbol appears on the left side of the budget input field
- Placeholder shows "0.00"
- Input accepts decimal numbers

**Test Data:**
- N/A (visual verification)

---

### TC-CE-025: Verify location dropdown suggestions appear
**Priority:** Low
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Click on the "Location" field
2. Observe dropdown suggestions

**Expected Results:**
- Dropdown displays with suggestions:
- Home
- Restaurant
- Park
- Beach
- Hotel
- Community Center
- Banquet Hall
- Garden
- Cafe
- Event Venue
- Office
- Church
- Temple
- Outdoor Location
- Friend's House

**Test Data:**
- N/A (visual verification)

---

### TC-CE-026: Verify date picker prevents past dates
**Priority:** Medium
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Click on "Event Date" field
2. Try to select yesterday's date

**Expected Results:**
- Date picker has minimum date set to today
- Past dates are disabled/grayed out
- User cannot select past dates from calendar

**Test Data:**
- N/A (UI validation)

---

### TC-CE-027: Verify form retains data after validation error
**Priority:** Medium
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Fill in "Event Name" with "Test Event"
2. Fill in "Event Date" with yesterday's date (invalid)
3. Fill in "Location" with "Home"
4. Fill in "Budget" with "100"
5. Fill in "Description" with "Test description"
6. Click "Create Event" button

**Expected Results:**
- Form shows validation error
- All filled fields retain their values:
- Event Name: "Test Event"
- Location: "Home"
- Budget: "100"
- Description: "Test description"
- User doesn't have to re-enter valid data

**Test Data:**
- event_name: "Test Event"
- event_date: Date.yesterday
- location: "Home"
- budget: 100
- description: "Test description"

---

### TC-CE-028: Verify recipients section only shows if recipients exist
**Priority:** Low
**Preconditions:**
- User is logged in

**Test Steps:**
1. As user with NO recipients, visit Create Event page
2. Verify recipients section
3. Create a recipient
4. Visit Create Event page again

**Expected Results:**
- When no recipients exist: recipients section is not displayed
- When recipients exist: recipients section displays with checkboxes

**Test Data:**
- N/A

---

### TC-CE-029: Verify cancel button returns to dashboard
**Priority:** Low
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Fill in some form fields
2. Click "Cancel" button

**Expected Results:**
- User is redirected to dashboard
- Event is NOT created
- No data is saved
- No confirmation dialog appears

**Test Data:**
- N/A

---

### TC-CE-030: Verify back button returns to dashboard
**Priority:** Low
**Preconditions:**
- User is logged in
- User is on the Create Event page

**Test Steps:**
1. Click "Back to Dashboard" link at top

**Expected Results:**
- User is redirected to dashboard
- Event is NOT created

**Test Data:**
- N/A

---

## INTEGRATION TEST SCENARIOS

### TC-CE-031: Create event and verify it appears in dashboard recent events
**Priority:** High
**Preconditions:**
- User is logged in
- User is on dashboard with 0 events

**Test Steps:**
1. Click "Create Event" button from Events card
2. Fill in event details
3. Submit form
4. Verify redirect to dashboard

**Expected Results:**
- Event appears in "Recent Events" section
- Event count updates from 0 to 1
- Event shows with correct date and location

**Test Data:**
- event_name: "New Event"
- event_date: Date.tomorrow

---

### TC-CE-032: Create multiple events and verify sorting
**Priority:** Medium
**Preconditions:**
- User is logged in

**Test Steps:**
1. Create Event 1 with date: today + 5 days
2. Create Event 2 with date: today + 2 days
3. Create Event 3 with date: today + 10 days
4. Navigate to Events list page

**Expected Results:**
- Events appear in "Upcoming Events" section
- Events are sorted by date (ascending):
1. Event 2 (today + 2 days)
2. Event 1 (today + 5 days)
3. Event 3 (today + 10 days)

**Test Data:**
- Multiple events with different dates

---

### TC-CE-033: Flash message displays and auto-dismisses
**Priority:** Medium
**Preconditions:**
- User is logged in
- User creates an event

**Test Steps:**
1. Create an event successfully
2. Observe flash message

**Expected Results:**
- Success flash message appears in top-right corner
- Message shows: "Event '[name]' created successfully!"
- Message has green background with success icon
- Message auto-dismisses after 4 seconds with fade animation

**Test Data:**
- N/A

---

## SUMMARY OF TEST COVERAGE

### Total Test Cases: 33

**By Priority:**
- High Priority: 12 test cases
- Medium Priority: 11 test cases
- Low Priority: 10 test cases

**By Category:**
- Positive Tests: 8 test cases
- Negative Tests: 8 test cases
- Edge Cases: 5 test cases
- Security Tests: 2 test cases
- UI/UX Tests: 7 test cases
- Integration Tests: 3 test cases

