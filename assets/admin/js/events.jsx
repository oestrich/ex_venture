import React from 'react';

class BaseEffect extends React.Component {
  constructor(props) {
    super(props);

    this.handleUpdateField = this.handleUpdateField.bind(this);
    this.castField = this.castField.bind(this);
  }

  castField(field, value) {
    return value;
  }

  handleUpdateField(field) {
    return (event) => {
      let value = event.target.value;
      value = this.castField(field, value);
      this.setState({[field]: value});

      let effect = Object.assign(this.state, {[field]: value});
      this.props.handleUpdate(effect);
    }
  }
}

class DamageEffect extends BaseEffect {
  constructor(props) {
    super(props);

    let effect = props.effect;

    this.state = {
      kind: "damage",
      type: effect.type,
      amount: effect.amount,
    };
  }

  castField(field, value) {
    switch (field) {
      case "amount":
        return parseInt(value);

      default:
        return value;
    }
  }

  render() {
    let type = this.state.type;
    let amount = this.state.amount;

    return (
      <div className="form-group row">
        <label className="col-md-4">Kind: damage</label>
        <div className="col-md-8">
          <div className="row">
            <div className="col-md-4">
              <label>Damage Type</label>
              <input type="text" value={type} className="form-control" onChange={this.handleUpdateField("type")} />
            </div>

            <div className="col-md-4">
              <label>Amount</label>
              <input type="number" value={amount} className="form-control" onChange={this.handleUpdateField("amount")} />
            </div>
          </div>
        </div>
      </div>
    );
  }
}

class DamageTypeEffect extends React.Component {
  constructor(props) {
    super(props);

    let effect = props.effect;

    this.state = {
      types: effect.types,
      newType: "",
    };

    this.handleKeyPress = this.handleKeyPress.bind(this);
    this.handleNewType = this.handleNewType.bind(this);

    this.addType = this.addType.bind(this);
    this.removeType = this.removeType.bind(this);
  }

  handleNewType(event) {
    let value = event.target.value;
    this.setState({newType: value});
  }

  handleKeyPress(event) {
    if (event.key == 'Enter') {
      event.preventDefault();
      this.addType(event);
    }
  }

  addType(event) {
    event.preventDefault();

    let newType = this.state.newType;

    if (newType != "") {
      let types = [newType, ...this.state.types];
      this.setState({
        types: types,
        newType: "",
      });
      this.props.handleUpdate({
        kind: "damage/type",
        types: types,
      });
    }
  }

  removeType(type) {
    let types = this.state.types;
    let index = types.indexOf(type);
    types.splice(index, 1);
    this.setState({
      types: types,
    })
  }

  render() {
    let types = this.state.types;
    let removeType = this.removeType;

    return (
      <div className="form-group row">
        <label className="col-md-4">Kind: damage/type</label>
        <div className="col-md-8">
          <div className="row">
            <ul>
              {types.map(function(type, index) {
                return (
                  <li key={index}>
                    {type}
                    <i onClick={() => removeType(type)} style={{paddingLeft: "15px"}} className="fa fa-times"></i>
                  </li>
                );
              })}
            </ul>
          </div>

          <div className="row">
            <div className="col-md-4">
              <input type="text" value={this.state.newType} className="form-control" onKeyPress={this.handleKeyPress} onChange={this.handleNewType} />
            </div>
            <div className="col-md-4">
              <a href="#" onClick={this.addType} className="btn btn-primary">Add</a>
            </div>
          </div>
        </div>
      </div>
    );
  }
}

class DamageOverTimeEffect extends BaseEffect {
  constructor(props) {
    super(props);

    let effect = props.effect;

    this.state = {
      kind: "damage/over-time",
      type: effect.type,
      amount: effect.amount,
      every: effect.amount,
      count: effect.amount,
    };
  }

  castField(field, value) {
    switch (field) {
      case "amount":
      case "every":
      case "count":
        return parseInt(value);

      default:
        return value;
    }
  }

  render() {
    let type = this.state.type;
    let amount = this.state.amount;
    let every = this.state.every;
    let count = this.state.count;

    return (
      <div className="form-group row">
        <label className="col-md-4">Kind: damage/over-time</label>
        <div className="col-md-8">
          <div className="row">
            <div className="col-md-4">
              <label>Damage Type</label>
              <input type="text" value={type} className="form-control" onChange={this.handleUpdateField("type")} />
            </div>
            <div className="col-md-4">
              <label>Amount</label>
              <input type="text" value={amount} className="form-control" onChange={this.handleUpdateField("amount")} />
            </div>
          </div>
          <div className="row">
            <div className="col-md-4">
              <label>Every X ms</label>
              <input type="text" value={every} className="form-control" onChange={this.handleUpdateField("every")} />
            </div>
            <div className="col-md-4">
              <label>Count</label>
              <input type="text" value={count} className="form-control" onChange={this.handleUpdateField("count")} />
            </div>
          </div>
        </div>
      </div>
    );
  }
}

class RecoverEffect extends BaseEffect {
  constructor(props) {
    super(props);

    let effect = props.effect;

    this.state = {
      kind: "recover",
      type: effect.type,
      amount: effect.amount,
    };
  }

  castField(field, value) {
    switch (field) {
      case "amount":
        return parseInt(value);

      default:
        return value;
    }
  }

  render() {
    let type = this.state.type;
    let amount = this.state.amount;

    return (
      <div className="form-group row">
        <label className="col-md-4">Kind: recover</label>
        <div className="col-md-8">
          <div className="row">
            <div className="col-md-4">
              <label>Stat to Recover</label>
              <input type="text" value={type} className="form-control" onChange={this.handleUpdateField("type")} />
            </div>

            <div className="col-md-4">
              <label>Amount</label>
              <input type="number" value={amount} className="form-control" onChange={this.handleUpdateField("amount")} />
            </div>
          </div>
        </div>
      </div>
    );
  }
}

class StatsEffect extends BaseEffect {
  constructor(props) {
    super(props);

    let effect = props.effect;

    this.state = {
      kind: "stats",
      field: effect.field,
      amount: effect.amount,
      mode: effect.mode,
    };
  }

  castField(field, value) {
    switch (field) {
      case "amount":
        return parseInt(value);

      default:
        return value;
    }
  }

  render() {
    let field = this.state.field;
    let amount = this.state.amount;
    let mode = this.state.mode;

    return (
      <div className="form-group row">
        <label className="col-md-4">Kind: stats</label>
        <div className="col-md-8">
          <div className="row">
            <div className="col-md-4">
              <label>Stat to increase</label>
              <input type="text" value={field} className="form-control" onChange={this.handleUpdateField("field")} />
            </div>

            <div className="col-md-4">
              <label>Amount</label>
              <input type="number" value={amount} className="form-control" onChange={this.handleUpdateField("amount")} />
            </div>
          </div>
          <div className="row">
            <div className="col-md-4">
              <label>Mode</label>
              <select onChange={this.handleUpdateField("mode")} value={mode} className="form-control">
                <option value="add">Add</option>
                <option value="subtract">Subtract</option>
                <option value="multiply">Multiply</option>
                <option value="divide">Divide</option>
              </select>
            </div>
          </div>
        </div>
      </div>
    );
  }
}

class StatsBoostEffect extends BaseEffect {
  constructor(props) {
    super(props);

    let effect = props.effect;

    this.state = {
      kind: "stats/boost",
      field: effect.field,
      amount: effect.amount,
      duration: effect.duration,
      mode: effect.mode,
    };
  }

  render() {
    let field = this.state.field;
    let amount = this.state.amount;
    let duration = this.state.duration;
    let mode = this.state.mode;

    return (
      <div className="form-group row">
        <label className="col-md-4">Kind: stats/boost</label>
        <div className="col-md-8">
          <div className="row">
            <div className="col-md-4">
              <label>Stat to Alter</label>
              <input type="text" value={field} className="form-control" onChange={this.handleUpdateField("field")} />
            </div>

            <div className="col-md-4">
              <label>Amount</label>
              <input type="number" value={amount} className="form-control" onChange={this.handleUpdateField("amount")} />
            </div>
          </div>
          <div className="row">
            <div className="col-md-4">
              <label>Duration</label>
              <input type="text" value={duration} className="form-control" onChange={this.handleUpdateField("duration")} />
            </div>

            <div className="col-md-4">
              <label>Mode</label>
              <select onChange={this.handleUpdateField("mode")} className="form-control">
                <option value="add">Add</option>
                <option value="subtract">Subtract</option>
                <option value="multiply">Multiply</option>
                <option value="divide">Divide</option>
              </select>
            </div>
          </div>
        </div>
      </div>
    );
  }
}

class Effect extends React.Component {
  constructor(props) {
    super(props);

    this.handleUpdate = this.handleUpdate.bind(this);
  }

  handleUpdate(effect) {
    this.props.handleUpdate(effect, this.props.index);
  }

  render() {
    let effect = this.props.effect;
    let handleUpdate = this.handleUpdate;

    switch (effect.kind) {
      case "damage":
        return (
          <DamageEffect effect={effect} handleUpdate={handleUpdate} />
        );

      case "damage/type":
        return (
          <DamageTypeEffect effect={effect} handleUpdate={handleUpdate} />
        );

      case "damage/over-time":
        return (
          <DamageOverTimeEffect effect={effect} handleUpdate={handleUpdate} />
        );

      case "recover":
        return (
          <RecoverEffect effect={effect} handleUpdate={handleUpdate} />
        );

      case "stats":
        return (
          <StatsEffect effect={effect} handleUpdate={handleUpdate} />
        );

      case "stats/boost":
        return (
          <StatsBoostEffect effect={effect} handleUpdate={handleUpdate} />
        );

      default:
        return (
          <div>Missing an effect: <b>{effect.kind}</b></div>
        );
    }
  }
}

class AddEffect extends React.Component {
  constructor(props) {
    super(props);

    this.addDamage = this.addDamage.bind(this);
    this.addDamageType = this.addDamageType.bind(this);
    this.addDamageOverTime = this.addDamageOverTime.bind(this);
    this.addRecover = this.addRecover.bind(this);
    this.addStats = this.addStats.bind(this);
    this.addStatsBoost = this.addStatsBoost.bind(this);
  }

  addDamage(event) {
    event.preventDefault();

    this.props.addEffect({
      kind: "damage",
      type: "slashing",
      amount: 10,
    });
  }

  addDamageType(event) {
    event.preventDefault();

    this.props.addEffect({
      kind: "damage/type",
      types: ["slashing"],
    });
  }

  addDamageOverTime(event) {
    event.preventDefault();

    this.props.addEffect({
      kind: "damage/over-time",
      type: "slashing",
      amount: 10,
      every: 1000,
      count: 3,
    });
  }

  addRecover(event) {
    event.preventDefault();

    this.props.addEffect({
      kind: "recover",
      type: "health",
      amount: 10,
    });
  }

  addStats(event) {
    event.preventDefault();

    this.props.addEffect({
      kind: "stats",
      field: "strength",
      amount: 10,
    });
  }

  addStatsBoost(event) {
    event.preventDefault();

    this.props.addEffect({
      kind: "stats/boost",
      field: "strength",
      amount: 10,
      duration: 1000,
      mode: "add",
    });
  }

  render() {
    return (
      <div>
        <div>
          <a href="#" className="btn btn-default" onClick={this.addDamage}>Add 'damage'</a>
          <a href="#" className="btn btn-default" onClick={this.addDamageType}>Add 'damage/type'</a>
          <a href="#" className="btn btn-default" onClick={this.addDamageOverTime}>Add 'damage/over-time'</a>
        </div>
        <div>
          <a href="#" className="btn btn-default" onClick={this.addRecover}>Add 'recover'</a>
          <a href="#" className="btn btn-default" onClick={this.addStats}>Add 'stats'</a>
          <a href="#" className="btn btn-default" onClick={this.addStatsBoost}>Add 'stats/boost'</a>
        </div>
        <div>
          <a href="https://exventure.org/admin/effects/" target="_blank" className="btn btn-default">Documentation</a>
        </div>
      </div>
    );
  }
}

export default class Effects extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      effects: props.effects,
    }

    this.handleUpdate = this.handleUpdate.bind(this);
    this.addEffect = this.addEffect.bind(this);
    this.removeEffect = this.removeEffect.bind(this);
  }

  handleUpdate(effect, index) {
    let effects = this.state.effects;
    effects[index] = effect;
    this.setState({
      effects: effects,
    });
  }

  addEffect(effect) {
    this.setState({effects: [...this.state.effects, effect]});
  }

  removeEffect(index) {
    let effects = this.state.effects;
    effects.splice(index, 1);
    this.setState({effects: effects});
  }

  render() {
    let effects = this.state.effects;
    let handleUpdate = this.handleUpdate;

    let effectsJSON = JSON.stringify(effects);
    let removeEffect = this.removeEffect;

    return (
      <div>
        <input type="hidden" name={this.props.name} value={effectsJSON} />

        {effects.map((effect, index) => {
          let onClick = (event) => {
            event.preventDefault();
            removeEffect(index);
          }

          return (
            <div key={index}>
              <Effect effect={effect} index={index} handleUpdate={handleUpdate} />
              <a href="#" onClick={onClick}>Remove</a>
              <hr />
            </div>
          );
        })}

        <AddEffect addEffect={this.addEffect} />
      </div>
    );
  }
}
