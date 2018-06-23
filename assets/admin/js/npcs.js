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
          case "endurance_points":
          case "max_endurance_points":
            newStats[key] = value + Math.round(5.5 * level);
            break;

          default:
            newStats[key] = value + Math.round(1.1 * level);
        }
      });

      let formValue = JSON.stringify(newStats, null, 2);

      this.statsElement.value = formValue;
    });
  }
}

window.NPCLeveler = NPCLeveler;
