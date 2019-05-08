class VanguardCard < StandardCard
  def parse_oracle_text
    # include Hand/Life modifier at the end of oracle_text
    super << labeled_row(:pt)
  end
end
