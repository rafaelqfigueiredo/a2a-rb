# Task lifecycle

Tasks are the unit of work in the A2A protocol. This example covers fetching,
inspecting, transitioning (server-side), listing, and cancelling tasks.

## Fetch and inspect a task

```ruby
require "a2a"

client = A2A::Client.new(
  protocol: A2A::Protocol::HttpJson.new(url: "https://agent.example.com")
)

task = client.get_task("task-abc123")

puts task.id
puts task.status.state       # "task_state_working"
puts task.terminal?          # false

# Fetch with history
task = client.get_task("task-abc123", history_length: 5)
task.history.each { |msg| puts msg.parts.first.text }
```

## Task states

```ruby
# State constants
A2A::Task::State::SUBMITTED      # initial state
A2A::Task::State::WORKING        # agent is processing
A2A::Task::State::INPUT_REQUIRED # agent needs more input (resumable)
A2A::Task::State::AUTH_REQUIRED  # agent needs authentication (resumable)
A2A::Task::State::COMPLETED      # terminal
A2A::Task::State::FAILED         # terminal
A2A::Task::State::CANCELED       # terminal
A2A::Task::State::REJECTED       # terminal

# Predicates
A2A::Task::State.terminal?("task_state_completed") # true
A2A::Task::State.terminal?("task_state_working")   # false

# Collections
A2A::Task::State::TERMINAL  # all four terminal states
A2A::Task::State::RESUMABLE # [INPUT_REQUIRED, AUTH_REQUIRED]
```

## Server-side: transitioning a task

`Task#transition_to` returns a new immutable `Task` with an updated status.
The original task is never mutated. Raises `TaskNotCancelableError` if already
in a terminal state.

```ruby
task = A2A::Task.new(
  id: "t1",
  status: A2A::Task::Status.new(state: A2A::Task::State::SUBMITTED)
)

working = task.transition_to(A2A::Task::State::WORKING)

# Attach a message and timestamp
done = working.transition_to(
  A2A::Task::State::COMPLETED,
  message: A2A::Message.new(
    id: SecureRandom.uuid,
    role: A2A::Role::AGENT,
    parts: [A2A::Part::Text.new(text: "Here is your summary.")]
  ),
  timestamp: Time.now.utc.iso8601
)

puts done.terminal? # true

# Attempting to transition from a terminal state raises:
done.transition_to(A2A::Task::State::WORKING)
# => A2A::TaskNotCancelableError: task t1 is already in terminal state task_state_completed
```

## List tasks

```ruby
response = client.list_tasks(page_size: 20)

response.tasks.each do |task|
  puts "#{task.id}: #{task.status.state}"
end

# Paginate
if response.next_page_token
  next_page = client.list_tasks(page_size: 20, page_token: response.next_page_token)
end

# Filter by state
response = client.list_tasks(status: A2A::Task::State::WORKING)
```

## Cancel a task

```ruby
# By ID
updated = client.cancel_task("task-abc123")
puts updated.status.state # "task_state_canceled"

# By Task object — raises locally if already terminal (no network round-trip)
task = client.get_task("task-abc123")

if task.terminal?
  puts "Already done: #{task.status.state}"
else
  client.cancel_task(task)
end
```

## Working with artifacts

```ruby
task = client.get_task("task-abc123")

task.artifacts.each do |artifact|
  puts artifact.name
  artifact.parts.each do |part|
    case part
    when A2A::Part::Text  then puts part.text
    when A2A::Part::File  then puts part.url || "(inline #{part.media_type})"
    when A2A::Part::Data  then pp part.data
    end
  end
end
```
