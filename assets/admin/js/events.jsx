import React from 'react';

class DamageEffect extends React.Component {
  constructor(props) {
    super(props);

    let effect = props.effect;

    this.state = {
      type: effect.type,
      amount: effect.amount,
    };

    this.handleTypeChange = this.handleTypeChange.bind(this);
    this.handleAmountChange = this.handleAmountChange.bind(this);
  }

  handleTypeChange(event) {
    let value = event.target.value;

    this.setState({type: value});

    this.props.handleUpdate({
      kind: "damage",
      type: value,
      amount: this.state.amount,
    });
  }

  handleAmountChange(event) {
    let value = event.target.value;

    this.setState({amount: value});

    this.props.handleUpdate({
      kind: "damage",
      type: this.state.type,
      amount: value,
    });
  }

  render() {
    let type = this.state.type;
    let amount = this.state.amount;

    return (
      <div className="form-group">
        <label className="col-md-4">Kind: damage</label>
        <div className="col-md-8">
          <div className="row">
            <div className="col-md-4">
              <label>Damage Type</label>
              <input type="text" value={type} className="form-control" onChange={this.handleTypeChange} />
            </div>

            <div className="col-md-4">
              <label>Amount</label>
              <input type="number" value={amount} className="form-control" onChange={this.handleAmountChange} />
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
      this.addType(event);
    }
  }

  addType(event) {
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
      <div className="form-group">
        <label className="col-md-4">Kind: damage/type</label>
        <div className="col-md-8">
          <ul className="row">
            {types.map(function(type, index) {
              return (
                <li key={index}>
                  {type}
                  <i onClick={() => removeType(type)} className="fa fa-times"></i>
                </li>
              );
            })}
          </ul>
          <input type="text" value={this.state.newType} className="form-control" onKeyPress={this.handleKeyPress} onChange={this.handleNewType} />
          <button onClick={this.addType} className="btn btn-primary">Add</button>
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

      default:
        return (
          <div>Missing an effect: <b>{effect.kind}</b></div>
        );
    }
  }
}

export default class Effects extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      effects: props.effects,
    }

    this.onSave = this.onSave.bind(this);
    this.handleUpdate = this.handleUpdate.bind(this);
  }

  handleUpdate(effect, index) {
    let effects = this.state.effects;
    effects[index] = effect;
    this.setState({
      effects: effects,
    });
  }

  onSave(event) {
    event.preventDefault();
    console.log(JSON.stringify(this.state.effects));
  }

  render() {
    let effects = this.state.effects;
    let handleUpdate = this.handleUpdate;

    return (
      <div>
        {effects.map(function (effect, index) {
          return (
            <div key={index}>
              <Effect effect={effect} index={index} handleUpdate={handleUpdate}/>
              <hr />
            </div>
          );
        })}
        <button onClick={this.onSave} className="btn btn-primary">Save</button>
      </div>
    );
  }
}
