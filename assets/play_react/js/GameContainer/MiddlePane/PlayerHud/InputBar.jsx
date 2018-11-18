import React from 'react';

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
        <input onChange={handleChange} name="msg" type="text" />
      </form>
    </div>
  );
};

export default InputBar;
