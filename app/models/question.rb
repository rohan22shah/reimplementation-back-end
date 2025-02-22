class Question < ApplicationRecord
    belongs_to :questionnaire # each question belongs to a specific questionnaire
    has_many :question_advices, dependent: :destroy # for each question, there is separate advice about each possible score
    
    validates :seq, presence: true # user must define sequence for a question
    validates :seq, numericality: true # sequence must be numeric
    validates :txt, length: { minimum: 0, allow_nil: false, message: "can't be nil" } # user must define text content for a question
    validates :question_type, presence: true # user must define type for a question
    validates :break_before, presence: true
    
    # Class variables
    NUMERIC = 'Numeric'.freeze # Display string for NUMERIC questions
    TRUE_FALSE = 'True/False'.freeze # Display string for TRUE_FALSE questions
    GRADING_TYPES = [[NUMERIC, false], [TRUE_FALSE, true]].freeze
  
    CHECKBOX = 'Checkbox'.freeze # Display string for NUMERIC questions
    TEXT_FIELD = 'TextField'.freeze
    TEXTAREA = 'TextArea'.freeze # Display string for TRUE_FALSE questions
    DROPDOWN = 'DropDown'.freeze
    UPLOAD_FILE = 'UploadFile'.freeze
    RATING = 'Rating'.freeze
  
    GRADING_TYPES_CUSTOM = [[CHECKBOX, 0], [TEXT_FIELD, 1], [TEXTAREA, 2], [DROPDOWN, 3], [UPLOAD_FILE, 4], [RATING, 5]].freeze
    WEIGHTS = [['1', 1], ['2', 2], ['3', 3], ['4', 4], ['5', 5]].freeze
    ANSWERS = [['1', 1], ['2', 2], ['3', 3], ['4', 4]].freeze # a hash used while creating a quiz questionnaire
    ANSWERS_TRUE_FALSE = [['1', 1], ['2', 2]].freeze
    ANSWERS_MCQ_CHECKED = [['1', 1], ['0', 2]].freeze
    RATINGS = [['Very Easy', 1], ['Easy', 2], ['Medium', 3], ['Difficult', 4], ['Very Difficult', 5]].freeze
    attr_accessor :checked
  

    def delete
      QuestionAdvice.where(question_id: id).find_each(&:destroy)
      destroy
    end

    # for quiz questions, we store 'TrueFalse', 'MultipleChoiceCheckbox', 'MultipleChoiceRadio' in the DB, and the full names are returned below
    def get_formatted_question_type
      question_type = self.question_type
      statement = ''
      if question_type == 'TrueFalse'
        statement = 'True/False'
      elsif question_type == 'MultipleChoiceCheckbox'
        statement = 'Multiple Choice - Checked'
      elsif question_type == 'MultipleChoiceRadio'
        statement = 'Multiple Choice - Radio'
      end
      statement
    end
  
    # this method return questions (question_ids) in one assignment whose comments field are meaningful (ScoredQuestion and TextArea)
    def self.get_all_questions_with_comments_available(assignment_id)
      question_ids = []
      questionnaires = Assignment.find(assignment_id).questionnaires.select { |questionnaire| questionnaire.questionnaire_type == 'ReviewQuestionnaire' }
      questionnaires.each do |questionnaire|
        questions = questionnaire.questions.select { |question| question.is_a?(ScoredQuestion) || question.instance_of?(TextArea) }
        questions.each { |question| question_ids << question.id }
      end
      question_ids
    end
  
    def self.import(row, _row_header, _session, q_id = nil)
      if row.length != 5
        raise ArgumentError,  'Not enough items: expect 3 columns: your login name, your full name' \
                              '(first and last name, not separated with the delimiter), and your email.'
      end
      # questionnaire = Questionnaire.find_by_id(_id)
      questionnaire = Questionnaire.find_by(id: q_id)
      raise ArgumentError, 'Questionnaire Not Found' if questionnaire.nil?
  
      questions = questionnaire.questions
      qid = 0
      questions.each do |q|
        if q.seq == row[2].strip.to_f
          qid = q.id
          break
        end
      end
  
      if qid > 0
        # question = Question.find_by_id(qid)
        question = Question.find_by(id: qid)
        attributes = {}
        attributes['txt'] = row[0].strip
        attributes['question_type'] = row[1].strip
        attributes['seq'] = row[2].strip.to_f
        attributes['size'] = row[3].strip
        attributes['break_before'] = row[4].strip
        question.questionnaire_id = q_id
        question.update(attributes)
      else
        attributes = {}
        attributes['txt'] = row[0].strip
        attributes['question_type'] = row[1].strip
        attributes['seq'] = row[2].strip.to_f
        attributes['size'] = row[3].strip
        # attributes["break_before"] = row[4].strip
        question = Question.new(attributes)
        question.questionnaire_id = q_id
        question.save
      end
    end
  
    def self.export_fields(_options)
      fields = ['Seq', 'Question', 'question_type', 'Weight', 'text area size', 'max_label', 'min_label']
      fields
    end
  
    def self.export(csv, parent_id, _options)
      questionnaire = Questionnaire.find(parent_id)
      questionnaire.questions.each do |question|
        csv << [question.seq, question.txt, question.question_type,
                question.weight, question.size, question.max_label,
                question.min_label]
      end
    end

end
  