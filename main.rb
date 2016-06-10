require 'highline/import'
require 'stripe'
require 'dotenv'
require 'yaml'

Dotenv.load

def create_plan_dialog
  puts "Great! Let's create a new plan!"

  plan_name = ask_string('Plan name:')
  plan_id = ask_string('Plan id:')
  currency = ask_string('Currency:')
  amount = ask_string('Amount (in cents)')
  interval_question = 'Plan Interval'
  interval_choices = %w(month year)
  interval = ask_single_choice(interval_question, interval_choices)
  environments = ask_environment

  create_plan_in_stripe(plan_id, plan_name, amount, interval, currency, environments)
end

def list_environments
  environments_array = environments
  puts 'Environments available:'
  puts environments_array
end

def environments
  environments = ENV['STRIPE_ENVIRONMENTS']
  raise 'Expecting a comma separated list of environments, but not found :(' unless environments
  environments.split(',')
end

def validate_environments
  environments_array = environments
  environments_array.map { |environment| api_key_from_environment(environment) }
end

def api_key_from_environment(environment)
  environment_variable_key = ENV["STRIPE_API_KEY_#{environment.upcase}"]
  raise "no api key was found for environment: #{environment}" unless environment_variable_key
  environment_variable_key
end

def validate_multiple_choice_answer_in_range(answer, range)
  matches_expression = answer =~ /(?:[1-9],)+[1-9]|^[\d]$/

  answer.split(',').each do |number|
    return false unless range.include? number.to_i
  end

  matches_expression
end

def ask_choice(question, range, choices)
  choices = Hash[range.zip choices]
  numerated_choices = choices.map { |k, v| "#{k} - #{v}" }.join("\n")

  choice_index = ask(
    "#{question}\n#{numerated_choices}",
    Integer
  ) { |q| q.in = range }

  choices[choice_index]
end

def ask_single_choice(question, possible_choices)
  range = (1..possible_choices.length).to_a

  ask_choice(question, range, possible_choices)
end

def ask_single_choice_with_all(question, original_possible_choices)
  range = (0..original_possible_choices.length).to_a
  possible_choices = ['all'] + original_possible_choices
  choice = ask_choice(question, range, possible_choices)

  if choice == 'all'
    original_possible_choices
  else
    [choice]
  end
end

def ask_multiple_choice(question, range, choices)
  choices_hash = Hash[range.zip choices]
  numerated_choices = choices_hash.map { |k, v| "#{k} - #{v}" }.join("\n")

  choice_index = ask(
    format('%s\n%s', question, numerated_choices),
    String
  ) { |q| q.validate = ->(p) { validate_multiple_choice_answer_in_range(p.to_s, range) } }

  selected_choices = []

  choice_index.split(',').each do |index|
    selected_choices.push(choices_hash[index.to_i])
  end

  selected_choices
end

def ask_multiple_choices_with_all(question, original_choices)
  range = (0..original_choices.length).to_a
  possible_choices = ['all'] + original_choices
  selected_choices = ask_multiple_choice(question, range, possible_choices)

  if selected_choices == ['all']
    original_choices
  else
    selected_choices
  end
end

def ask_environment
  environment_question = 'Environment'
  environment_choices = environments
  ask_multiple_choices_with_all(environment_question, environment_choices)
end

def ask_string(question, choices = {})
  aux = choices.map { |k, v| "#{k} - #{v}" }.join("\n")

  ask(
    "\n" + question + "\n" + aux,
    String
  ) { |q| q.validate = /\w+/ }
end

def ask_int(question, choices)
  aux = choices.map { |k, v| "#{k} - #{v}" }.join("\n")

  ask(
    question + "\n" + aux,
    Integer
  ) { |q| q.validate = /\d+/ }
end

def create_plan_in_stripe(id, name, amount, interval, currency, environments)
  puts 'Gathered required information, creating plan in stripe...'
  environments.each do |environment|
    set_api_key_for_environment(environment)
    Stripe::Plan.create(
      'id' => id,
      'name' => name,
      'amount' => amount,
      'interval' => interval,
      'currency' => currency
    )
  end
  puts 'Done :D'
end

def list_plans_in_environment
  environments = ask_environment

  environments.each do |environment|
    puts "\nAvailable plans in #{environment}:"
    set_api_key_for_environment(environment)

    Stripe::Plan.all.each { |plan| puts "- #{plan.id}" }
  end
end

def set_api_key_for_environment(environment)
  Stripe.api_key = api_key_from_environment(environment)
end

def action_choices
  [
    'Create a new plan',
    'Copy an existing plan to another environment',
    'List available environments',
    'List available plans in a given environment'
  ]
end

def main
  validate_environments
  action_question = 'What would you like to do?'

  action = ask_single_choice(action_question, action_choices)

  case action
  when 'Create a new plan' then create_plan_dialog
  when 'List available environments' then list_environments
  when 'List available plans in a given environment' then list_plans_in_environment
  else 'Not implemented yet :('
  end
end

main
