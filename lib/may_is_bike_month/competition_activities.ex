defmodule MayIsBikeMonth.CompetitionActivities do
  @moduledoc """
  The CompetitionActivities context.
  """

  @ignored_strava_keys [
    "map",
    "segment_efforts",
    "splits_metric",
    "splits_standard",
    "laps",
    "stats_visibility"
  ]

  @included_strava_visibilities ["everyone", "followers_only"]

  import Ecto.Query, warn: false
  alias MayIsBikeMonth.{Repo, CompetitionActivities.CompetitionActivity, CompetitionParticipants}

  @doc """
  Returns the list of competition_activities.

  ## Examples

      iex> list_competition_activities()
      [%CompetitionActivity{}, ...]

  """
  def list_competition_activities do
    from(CompetitionActivity)
    |> order_by([ca], desc: ca.start_at)
    |> Repo.all()
  end

  @doc """
    Example filter:
    %{competition_participant_id: 1, start_date: ~D[2023-05-22], end_date: ~D[2023-05-28]}
  """
  def list_competition_activities(filter) when is_map(filter) do
    filter_with_nils =
      %{
        competition_participant_id: nil,
        start_date: nil,
        end_date: nil,
        include_in_competition: nil,
        order_direction: :desc
      }
      |> Map.merge(filter)

    order_by =
      if(filter_with_nils.order_direction == :desc, do: [desc: :start_at], else: [asc: :start_at])

    from(CompetitionActivity)
    # NOTE: in_period must come first because it includes or_where
    |> in_period(filter_with_nils)
    |> for_include_in_competition(filter_with_nils)
    |> for_competition_participant_id(filter_with_nils)
    |> order_by(^order_by)
    |> Repo.all()
  end

  defp in_period(query, %{start_date: nil, end_date: nil}), do: query

  defp in_period(query, %{start_date: start_date, end_date: end_date}) do
    date_range =
      Date.range(start_date, end_date)
      |> Enum.to_list()

    from ca in query,
      where: ca.start_date in ^date_range,
      or_where: ca.end_date in ^date_range
  end

  defp for_include_in_competition(query, %{include_in_competition: nil}), do: query

  defp for_include_in_competition(query, %{
         include_in_competition: include_in_competition
       }) do
    query
    |> where(include_in_competition: ^include_in_competition)
  end

  defp for_competition_participant_id(query, %{competition_participant_id: nil}), do: query

  defp for_competition_participant_id(query, %{
         competition_participant_id: competition_participant_id
       }) do
    query
    |> where(competition_participant_id: ^competition_participant_id)
  end

  @doc """
  Gets a single competition_activity.

  Raises `Ecto.NoResultsError` if the Competition activity does not exist.

  ## Examples

      iex> get_competition_activity!(123)
      %CompetitionActivity{}

      iex> get_competition_activity!(456)
      ** (Ecto.NoResultsError)

  """
  def get_competition_activity!(id), do: Repo.get!(CompetitionActivity, id)

  def get_competition_activity_for_ids!(%{
        competition_participant_id: competition_participant_id,
        strava_id: strava_id
      }) do
    from(CompetitionActivity)
    |> where(competition_participant_id: ^competition_participant_id)
    |> where(strava_id: ^strava_id)
    |> first()
    |> Repo.one()
  end

  def get_competition_activity_for_ids(args) do
    with %CompetitionActivity{} = competition_activity <- get_competition_activity_for_ids!(args) do
      {:ok, competition_activity}
    else
      _ -> {:error, nil}
    end
  end

  def parse_strava_timezone(string) do
    Regex.replace(~r/\([^\)]*\)/, string, "")
    |> String.trim()
  end

  def strava_attrs_from_data(strava_data) do
    start_at = Timex.parse!(strava_data["start_date"], "{RFC3339z}")
    start_date = DateTime.to_date(Timex.parse!(strava_data["start_date_local"], "{RFC3339z}"))

    timezone = parse_strava_timezone(strava_data["timezone"])

    %{
      strava_id: "#{strava_data["id"]}",
      start_date: start_date,
      end_date: calculate_end_date(start_at, timezone, strava_data["moving_time"]),
      timezone: timezone,
      start_at: start_at,
      display_name: strava_data["name"],
      distance_meters: strava_data["distance"],
      elevation_meters: strava_data["total_elevation_gain"],
      moving_seconds: strava_data["moving_time"]
    }
  end

  def included_visibility?(visibility) do
    visibility in @included_strava_visibilities
  end

  def include_in_competition?(
        competition_participant,
        %{
          visibility: visibility,
          type: type,
          distance: distance,
          start_date: start_date,
          end_date: end_date
        }
      ) do
    competition_participant.include_in_competition &&
      included_visibility?(visibility) &&
      CompetitionParticipants.included_activity_type?(competition_participant, type) &&
      CompetitionParticipants.included_distance?(competition_participant, distance) &&
      CompetitionParticipants.included_in_competition_period?(
        competition_participant,
        start_date,
        end_date
      )
  end

  @doc """
  Creates a competition activity using the strava data that is passed in
  This is the way that all competition activities should be created!
  """
  def create_or_update_from_strava_data(competition_participant, strava_data) do
    strava_attrs = strava_attrs_from_data(strava_data)

    included_in_competition =
      include_in_competition?(competition_participant, %{
        visibility: strava_data["visibility"],
        type: strava_data["type"],
        distance: strava_data["distance"],
        start_date: strava_attrs.start_date,
        end_date: strava_attrs.end_date
      })

    new_attrs =
      Map.merge(strava_attrs, %{
        competition_participant_id: competition_participant.id,
        strava_data: Map.drop(strava_data, @ignored_strava_keys),
        include_in_competition: included_in_competition
      })

    with {:ok, competition_activity} <-
           get_competition_activity_for_ids(
             Map.take(new_attrs, [:competition_participant_id, :strava_id])
           ) do
      update_competition_activity(competition_activity, new_attrs)
    else
      _ -> create_competition_activity(new_attrs)
    end
  end

  def activity_dates(start_at, timezone, moving_seconds) do
    local_start_at = MayIsBikeMonth.TimeFormatter.in_timezone(start_at, timezone)
    end_at = local_start_at |> DateTime.add(moving_seconds)
    activity_dates(local_start_at, end_at)
  end

  def activity_dates(start_at_or_date, end_at_or_date) do
    Date.range(start_at_or_date, end_at_or_date)
    |> Enum.to_list()
  end

  def calculate_end_date(start_at, timezone, moving_seconds) do
    List.last(activity_dates(start_at, timezone, moving_seconds))
  end

  @doc """
  Creates a competition_activity.

  ## Examples

      iex> create_competition_activity(%{field: value})
      {:ok, %CompetitionActivity{}}

      iex> create_competition_activity(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_competition_activity(attrs \\ %{}) do
    %CompetitionActivity{}
    |> CompetitionActivity.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a competition_activity.

  ## Examples

      iex> update_competition_activity(competition_activity, %{field: new_value})
      {:ok, %CompetitionActivity{}}

      iex> update_competition_activity(competition_activity, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_competition_activity(%CompetitionActivity{} = competition_activity, attrs) do
    competition_activity
    |> CompetitionActivity.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a competition_activity.

  ## Examples

      iex> delete_competition_activity(competition_activity)
      {:ok, %CompetitionActivity{}}

      iex> delete_competition_activity(competition_activity)
      {:error, %Ecto.Changeset{}}

  """
  def delete_competition_activity(%CompetitionActivity{} = competition_activity) do
    Repo.delete(competition_activity)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking competition_activity changes.

  ## Examples

      iex> change_competition_activity(competition_activity)
      %Ecto.Changeset{data: %CompetitionActivity{}}

  """
  def change_competition_activity(%CompetitionActivity{} = competition_activity, attrs \\ %{}) do
    CompetitionActivity.changeset(competition_activity, attrs)
  end

  @doc """
  Returns a map of the data that is stored in the period for each competition_activity.

  """
  def period_score_data(%CompetitionActivity{} = competition_activity, start_date, period) do
    data = score_data(competition_activity)
    starts_in_previous_period = Date.compare(competition_activity.start_date, start_date) == :lt

    Map.merge(data, %{
      "dates" => MapSet.intersection(data["dates"], period) |> MapSet.to_list(),
      "distance_meters" => if(starts_in_previous_period, do: 0, else: data["distance_meters"]),
      "elevation_meters" => if(starts_in_previous_period, do: 0, else: data["elevation_meters"]),
      "starts_in_previous_period" => starts_in_previous_period
    })
  end

  # TODO: Make this private. It's only public for testing.
  def score_data(%CompetitionActivity{} = competition_activity) do
    dates =
      activity_dates(competition_activity.start_date, competition_activity.end_date)
      |> MapSet.new()

    %{
      "distance_meters" => competition_activity.distance_meters,
      "elevation_meters" => competition_activity.elevation_meters,
      "strava_id" => competition_activity.strava_id,
      "display_name" => competition_activity.display_name,
      "dates" => dates
    }
  end
end
