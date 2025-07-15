const importAll = (r) => r.keys().map(r);

//=== JS dependencies
import $ from 'jquery';
window.$ = window.jQuery = $;

//=== Medz theme core
import 'medz/scss/style-optimized.scss';
import 'medz/color-skins/color-custom';
import 'frontend/styles/theme-overrides';
import 'frontend/styles/custom';

//== Pages CSS
import 'frontend/styles/pages/bookings';

//=== Medz theme dependencies
require('jquery-sticky');

import "flatpickr/dist/flatpickr.css";

//=== Webfont icons
import 'medz/iconfonts/font-awesome/css/font-awesome.css';
import 'medz/iconfonts/feather/feather.css';

//== Custom style
import 'frontend/styles/custom/flatpickr';

require('bootstrap');

window.bootbox = require('bootbox');
require('jquery-serializejson');

//=== Images
// TODO: remove unused images imports
importAll(require.context('frontend/images', false, /\.(png|jpe?g)$/));

//==s Functions
require('frontend/functions/events_tracking.js');
require('frontend/functions/utils.js');

//=== Pages js
require('frontend/pages/common.js');
require('frontend/pages/home.js');
require('frontend/pages/referrals.js');
require('frontend/pages/pricing.js');
require('frontend/pages/team.js');
require('frontend/pages/bookings.js');
require('frontend/pages/booking_form.js');
require('frontend/pages/embed_team_page.js');
require('frontend/pages/practitioner_profile.js');