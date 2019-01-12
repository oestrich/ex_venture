import React from 'react';
import _ from 'lodash';

class Proficiency extends React.Component {
  render() {
    let name = this.props.name;
    let ranks = this.props.ranks;

    return (
      <li className="proficiency">
        <span>{name}</span> - <span>{ranks}</span>
      </li>
    );
  }
}

class NewRequirement extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      proficiencyId: null,
      requiredRanks: 0,
    };

    this.addRequirement = this.addRequirement.bind(this);
    this.handleUpdateField = this.handleUpdateField.bind(this);
  }

  addRequirement(event) {
    event.preventDefault();

    if (this.state.proficiencyId != null && this.state.requiredRanks != null) {
      this.props.addRequirement({
        id: this.state.proficiencyId,
        ranks: this.state.requiredRanks,
      });

      this.setState({
        proficiencyId: null,
        requiredRanks: 0,
      });
    }
  }

  castField(field, value) {
    switch (field) {
      case "proficiencyId":
      case "requiredRanks":
        if (value === "") {
          return null;
        } else {
          return parseInt(value);
        }

      default:
        return value;
    }
  }

  handleUpdateField(field) {
    return (event) => {
      let value = event.target.value;
      value = this.castField(field, value);
      this.setState({[field]: value});
    }
  }

  render() {
    let proficiencyId = this.state.proficiencyId || "";
    let requiredRanks = this.state.requiredRanks || "";

    let proficiencies = this.props.proficiencies;

    return (
      <div>
        <div className="row">
          <div className="col-md-4">
            <label>Proficiency</label>
            <select value={proficiencyId} className="form-control" onChange={this.handleUpdateField("proficiencyId")}>
              <option value="">Select Proficiency</option>
              {proficiencies.map(proficiency => {
                return (
                  <option key={proficiency.id} value={proficiency.id}>{proficiency.name}</option>
                );
              })}
            </select>
          </div>
          <div className="col-md-4">
            <label>Required Ranks</label>
            <input type="number" value={requiredRanks} className="form-control" onChange={this.handleUpdateField("requiredRanks")} />
          </div>
        </div>
        <div>
          <input type="submit" value="Add Requirement" className="btn btn-primary" onClick={this.addRequirement} />
        </div>
      </div>
    );
  }
}

class ExitProficiencies extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      proficiencies: [],
      showForm: false,
    };

    this.addRequirement = this.addRequirement.bind(this);
    this.showForm = this.showForm.bind(this);
  }

  addRequirement(proficiencyToAdd) {
    let oldProficiency = _.find(this.state.proficiencies, proficiency => {
      return proficiency.id == proficiencyToAdd.id;
    });

    if (oldProficiency == undefined) {
      this.setState({
        proficiencies: this.state.proficiencies.concat([proficiencyToAdd]),
        showForm: false,
      });
    }
  }

  renderProficencies() {
    if (this.state.proficiencies.length == 0) {
      return (
        <div>No proficiencies are required.</div>
      );
    } else {
      return (
        <ul className="proficiencies">
          {this.state.proficiencies.map(requirement => {
            let proficiency = _.find(this.props.proficiencies, proficiency => {
              return proficiency.id == requirement.id;
            })

            return <Proficiency key={proficiency.id} name={proficiency.name} ranks={requirement.ranks} />
          })}
        </ul>
      );
    }
  }

  showForm(event) {
    event.preventDefault();
    this.setState({
      showForm: true,
    });
  }

  renderNewForm() {
    if (this.state.showForm) {
      return (
        <NewRequirement proficiencies={this.props.proficiencies} addRequirement={this.addRequirement} />
      );
    } else {
      return (
        <a className="btn btn-primary" onClick={this.showForm}>
          <i className="fa fa-plus"></i>
          Add
        </a>
      );
    }
  }

  renderFormField() {
    let json = JSON.stringify(this.state.proficiencies);

    return (
      <input type="hidden" name={this.props.name} value={json} />
    );
  }

  render() {
    return (
      <div>
        {this.renderFormField()}
        {this.renderProficencies()}
        {this.renderNewForm()}
      </div>
    );
  }
}

export default ExitProficiencies;
