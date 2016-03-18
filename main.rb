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
  interval_choices = ['month', 'year']
  interval = ask_choice(interval_question, interval_choices)
  environment_question = 'Environment'
  environment_choices = get_environments
  environment = ask_choice(environment_question, environment_choices)
  create_plan_in_stripe(plan_id, plan_name, amount, interval, currency, environment)
end

def list_environments
  environments_array = get_environments
  puts "Environments available:"
  puts environments_array
end

def get_environments
  environments = ENV['STRIPE_ENVIRONMENTS']
  raise "Expecting a comma separated list of environments, but not found :(" unless environments
  environments.split(',')
end

def validate_environments
  environments_array = get_environments

  environments_array.map{|environment| get_api_key_from_environment(environment)}
end

def get_api_key_from_environment(environment)
  environment_variable_key = 'STRIPE_API_KEY_%s' % environment.upcase
  
  if not ENV[environment_variable_key]
    raise "no api key was found for environment: %s" % environment
  end

  return ENV[environment_variable_key]
end

def ask_choice(question, possible_answers)
  range = (1..possible_answers.length).to_a
  choices = Hash[range.zip possible_answers]

  numerated_choices = choices.map { |k, v| "#{k} - #{v}" }.join("\n")

  choice = ask(
    "%s\n%s" % [question, numerated_choices],
    Integer
  ) { |q| q.in = range}

  choices[choice]
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

def create_plan_in_stripe(id, name, amount, interval, currency, environment)
  puts "Gathered required information, creating plan in stripe..."
  set_api_key_for_environment(environment)

  Stripe::Plan.create(
    'id' => id,
    'name' => name,
    'amount' => amount,
    'interval' => interval,
    'currency' => currency,
  )

  puts "Done :D"
end

def list_plans_in_environment(environment)
  puts "\nPlans available in %s:" % environment

  set_api_key_for_environment(environment)
  stripe_plans = Stripe::Plan.all.each{|environment| puts "- %s" % environment.id}
end

def set_api_key_for_environment(environment)
  Stripe.api_key = get_api_key_from_environment(environment)
end

def main
  validate_environments
  question = 'What would you like to do?'
  answers = ['Create a new plan', 'Copy an existing plan to another environment', 'List available environments', 'List available plans in a given environment']

  action = ask_choice(question, answers)


  if action == 'Create a new plan'
    create_plan_dialog
  elsif action == 'List available environments' 
    list_environments
  else
    puts "Not implemented yet :("
  end
end

main
