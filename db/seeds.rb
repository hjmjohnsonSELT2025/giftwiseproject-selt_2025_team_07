user = User.first || User.create!(
  name: "Test User",
  email: "test@example.com",
  password: "password123"
)

Recipient.create!([
                    { name: "Mom", age: 50, relationship: "Mother", likes: "Cooking, Sarees", dislikes: "Cold food", user: user },
                    { name: "Dad", age: 55, relationship: "Father", likes: "Books, Watches", dislikes: "Loud music", user: user },
                    { name: "Sarah", age: 25, relationship: "Sister", likes: "Perfume, Fashion", dislikes: "Spicy food", user: user },
                    { name: "John", age: 30, relationship: "Friend", likes: "Tech gadgets, Travel", dislikes: "Delays", user: user }
                  ])
