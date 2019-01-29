import React from 'react';
import { format } from '../utils/color.js';

const VmlParser = ({ vmlString }) =>
  vmlString ? (
    <div dangerouslySetInnerHTML={{ __html: format(vmlString) }} />
  ) : null;

export default VmlParser;
