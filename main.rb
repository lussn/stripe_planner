require 'highline/import'
require 'stripe'
require 'dotenv'

Dotenv.load

def create_plan_dialog
  puts "Great! Let's create a new plan!"

  plan_name = ask_string('Plan name:')
  plan_id = ask_string('Plan id:')
  currency = ask_string('Currency:')
  amount = ask_string('Amount (in cents)')
  interval = ask_choice(
    'Plan Interval',
    {
      1 => 'month',
      2 => 'year'
    }
  )
  environments = ask_choice(
    'Environment',
  )

  create_plan_in_stripe(plan_id, plan_name, amount, interval, currency)
end

def list_environments
  environments = ENV['STRIPE_PLANS']
  environments_array = environments.split(',')
  
  puts "Environments available:"
  puts environments_array
end

def validate_environments
  environments = ENV['STRIPE_PLANS']
  if not environments
    puts "Expecting a comma separated list of environments, but not found :("
    return
  end

  environments_array = environments.split(',')

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
  aux = possible_answers.map { |k, v| "#{k} - #{v}" }.join("\n")

  choice = ask(
    question + "\n" + aux,
    Integer
  ) { |q| q.in = 1..possible_answers.length }

  possible_answers[choice]
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

def create_plan_in_stripe(id, name, amount, interval, currency)
  puts "Gathered required information, creating plan in stripe..."
  
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

  action = ask_choice(
    'What would you like to do?',
    {
      1 => 'Create a new plan',
      2 => 'Copy an existing plan to another environment',
      3 => 'List available environments',
      4 => 'List available plans in a given environment'
    }
  )

  if action == 'Create a new plan'
    create_plan_dialog
  elsif action == 'List available environments' 
    list_environments
  else
    puts "Not implemented yet :("
  end
end

main
