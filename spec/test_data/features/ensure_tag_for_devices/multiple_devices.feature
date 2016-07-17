@multiple_matches
Feature:

  @multiple
  Scenario:
    Given empty step

  Scenario Outline:
    Given <param>

    @multiple
    Examples:
      | param        |
      | empty step A |

    Examples:
      | param        |
      | empty step B |
      | empty step C |