var App = {
    setTimezone: function(timezone) {
        App.timezone = timezone;
    },
    EMAIL_REGEX: /([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+/,
    CONSTANTS: {
        USER: {
            ROLE_ADMINISTRATOR: 'administrator',
            ROLE_SUPERVISOR: 'supervisor',
            ROLE_RESTRICTED_PRACTITIONER: 'restricted practitioner',
            ROLE_PRACTITIONER: 'practitioner',
            ROLE_RECEPTIONIST: 'receptionist',
            ROLE_RESTRICTED_SUPERVISOR: 'restricted supervisor',
        }
    }
};
