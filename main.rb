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
  environments_array = get_environments
  puts 'Environments available:'
  puts environments_array
end

def get_environments
  environments = ENV['STRIPE_ENVIRONMENTS']
  raise 'Expecting a comma separated list of environments, but not found :(' unless environments
  environments.split(',')
end

def validate_environments
  environments_array = get_environments
  environments_array.map { |environment| get_api_key_from_environment(environment) }
end

def get_api_key_from_environment(environment)
  environment_variable_key = ENV["STRIPE_API_KEY_#{environment.upcase}"]
  raise "no api key was found for environment: #{environment}" unless environment_variable_key
  environment_variable_key
end

def ask_choice(question, range, possible_answers)
  choices = Hash[range.zip possible_answers]
  numerated_choices = choices.map { |k, v| "#{k} - #{v}" }.join("\n")

  choice_index = ask(
    "%s\n%s" % [question, numerated_choices],
    Integer
  ) { |q| q.in = range }

  choices[choice_index]
end

def ask_single_choice(question, possible_answers)
  range = (1..possible_answers.length).to_a

  ask_choice(question, range, possible_answers)
end

def ask_choice_with_all(question, original_possible_answers)
  range = (0..original_possible_answers.length).to_a
  possible_answers = ['all'] + original_possible_answers
  choice = ask_choice(question, range, possible_answers)

  if choice == 'all'
    original_possible_answers
  else
    [choice]
  end
end

def ask_environment
  environment_question = 'Environment'
  environment_choices = get_environments
  ask_choice_with_all(environment_question, environment_choices)
end

def ask_string(question, possible_answers = {})
  aux = possible_answers.map { |k, v| "#{k} - #{v}" }.join("\n")

  ask(
    "\n" + question + "\n" + aux,
    String
  ) { |q| q.validate = /\w+/ }
end

def ask_int(question, possible_answers)
  aux = possible_answers.map { |k, v| "#{k} - #{v}" }.join("\n")

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
    puts "\nPlans available in #{environment}:"
    set_api_key_for_environment(environment)

    Stripe::Plan.all.each { |plan| puts "- #{plan.id}" }
  end
end

def set_api_key_for_environment(environment)
  Stripe.api_key = get_api_key_from_environment(environment)
end

def main
  validate_environments
  question = 'What would you like to do?'
  answers = ['Create a new plan', 'Copy an existing plan to another environment', 'List available environments', 'List available plans in a given environment']

  action = ask_single_choice(question, answers)

  case action
    when 'Create a new plan' then create_plan_dialog
    when 'List available environments' then list_environments
    when 'List available plans in a given environment' then list_plans_in_environment
    else 'Not implemented yet :('
  end
end

main
