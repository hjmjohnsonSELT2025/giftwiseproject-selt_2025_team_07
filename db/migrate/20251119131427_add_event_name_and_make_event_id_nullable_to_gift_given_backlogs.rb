class AddEventNameAndMakeEventIdNullableToGiftGivenBacklogs < ActiveRecord::Migration[7.1]
  def change
    # 1. Add event_name column
    add_column :gift_given_backlogs, :event_name, :string

    # 2. Make event_id nullable
    change_column_null :gift_given_backlogs, :event_id, true
  end
end
