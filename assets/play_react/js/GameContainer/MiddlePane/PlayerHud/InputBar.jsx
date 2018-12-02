import React from 'react';
import styled from 'styled-components';

const Bar = styled.input`
  display: inline-block;
  color: #444;
  border: 1px solid #6177c8;
  background: #879ade;
  box-shadow: 0 2px 5px 0px #000000;
  border-radius: 5px;
  vertical-align: middle;
  max-height: 35px;
  height: 5px;
  width: 98.3%;
  padding: 5px;
  line-height: 5px;
`;

const InputBar = () => {
  let state = {};
  const handleSubmit = e => {
    e.preventDefault();
    e.target.reset();
    window.send(state);
  };
  const handleChange = e => {
    state = e.target.value;
  };
  return (
    <div>
      <form onSubmit={handleSubmit}>
        <Bar onChange={handleChange} name="msg" type="text" />
      </form>
    </div>
  );
};

export default InputBar;
