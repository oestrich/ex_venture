import React from 'react';
import { format } from '../utils/color.js';

const VmlParser = ({ vmlString }) => (
  <div dangerouslySetInnerHTML={{ __html: format(vmlString) }} />
);

export default VmlParser;
