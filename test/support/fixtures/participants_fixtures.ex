defmodule MayIsBikeMonth.ParticipantsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MayIsBikeMonth.Participants` context.
  """

  @doc """
  Generate a participant.
  """
  def participant_fixture(attrs \\ %{}) do
    {:ok, participant} =
      attrs
      |> Enum.into(%{
        first_name: "some first_name",
        image_url: "some image_url",
        last_name: "some last_name",
        strava_id: "2430215",
        strava_username: "some strava_username"
      })
      |> MayIsBikeMonth.Participants.create_participant()

    participant
  end
end
