require 'highline/import'
require 'stripe'
require 'dotenv'

Dotenv.load
Stripe.api_key = ENV['STRIPE_API_KEY']


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

  create_plan_in_stripe(plan_id, plan_name, amount, interval, currency)
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

def main

  action = ask_choice(
    'What would you like to do?',
    {
      1 => 'Create a new plan',
      2 => 'Copy an existing plan to another environment'
    }
  )

  if action == 'Create a new plan'
    create_plan_dialog
  else
    puts 'Not implemented yet :('
  end
end

main
