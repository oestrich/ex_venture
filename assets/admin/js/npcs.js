export class NPCLeveler {
  constructor(basicStats, levelElement, statsElement) {
    this.basicStats = basicStats;
    this.levelElement = levelElement;
    this.statsElement = statsElement;

    this.addEventListeners();
  }

  addEventListeners() {
    this.levelElement.addEventListener("change", event => {
      let level = parseInt(event.target.value, 10);
      let newStats = {};

      $.each(this.basicStats, (key, value) => {
        switch (key) {
          case "health_points":
          case "max_health_points":
          case "skill_points":
          case "max_skill_points":
            newStats[key] = value + 5;
            break;

          case "move_points":
          case "max_move_points":
            newStats[key] = value + 2;
            break;

          default:
            newStats[key] = value + 1;
        }
      });

      let formValue = JSON.stringify(newStats, null, 2);

      this.statsElement.value = formValue;
    });
  }
}

window.NPCLeveler = NPCLeveler;
