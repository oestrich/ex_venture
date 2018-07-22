from grafanalib.core import *


dashboard = Dashboard(
  title="ExVenture",
  rows=[
    Row(panels=[
      Graph(
        title="Player Count",
        dataSource='Prometheus',
        targets=[
          Target(
            expr='exventure_player_count',
            legendFormat="{{role}}",
          ),
        ],
      ),
      Graph(
        title="Logins",
        dataSource='Prometheus',
        targets=[
          Target(
            expr='exventure_login_total',
          ),
          Target(
            expr='exventure_login_failure_total',
          ),
        ],
      ),
      Graph(
        title="Sessions",
        dataSource='Prometheus',
        targets=[
          Target(
            expr='exventure_session_total',
            legendFormat="Sessions",
          ),
          Target(
            expr='exventure_session_recovery_total',
            legendFormat="Session Recoveries",
          ),
        ],
      ),
    ]),
  ],
).auto_panel_ids()
